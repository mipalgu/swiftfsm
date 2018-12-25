/*
 * RoundRobinScheduler.swift
 * swiftfsm
 *
 * Created by Callum McColl on 18/08/2015.
 * Copyright © 2015 Callum McColl. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgement:
 *
 *        This product includes software developed by Callum McColl.
 *
 * 4. Neither the name of the author nor the names of contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * -----------------------------------------------------------------------
 * This program is free software; you can redistribute it and/or
 * modify it under the above terms or under the terms of the GNU
 * General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/
 * or write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

#if os(OSX)
import Darwin
#elseif os(Linux)
import Glibc
#endif

import FSM
import IO
import MachineStructure
import MachineLoading
import swiftfsm
import Utilities

/**
 *  Responsible for the execution of machines.
 */
public class RoundRobinScheduler<Tokenizer: SchedulerTokenizer>: Scheduler where
    Tokenizer.Object == Machine,
    Tokenizer.SchedulerToken == SchedulerToken
{

    private let tokenizer: Tokenizer

    private let unloader: MachineUnloader

    private let scheduleHandler: ScheduleHandler
    
    private let stackLimit: Int
    
    private let printer: Printer
    
    fileprivate var promises: [FSM_ID: (fsm: AnyParameterisedFiniteStateMachine, stack: [PromiseData])] = [:]
    
    fileprivate var invocations: Bool = false
    
    public var fsms: [FSM_ID : FSMType] = [:]
    
    public var ids: [String: FSM_ID] = [:]
    
    /**
     *  Create a new `RoundRobinScheduler`.
     *
     *  - Parameter machines: All the `Machine`s that will be executed.
     */
    public init(tokenizer: Tokenizer, unloader: MachineUnloader, scheduleHandler: ScheduleHandler, stackLimit: Int = 8192, printer: Printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())) {
        self.tokenizer = tokenizer
        self.unloader = unloader
        self.scheduleHandler = scheduleHandler
        self.stackLimit = stackLimit
        self.printer = printer
    }
    
    /**
     *  Start executing all machines.
     */
    public func run(_ machines: [Machine]) -> Void {
        self.promises = [:]
        let tokens = self.tokenizer.separate(machines)
        tokens.forEach {
            $0.forEach {
                guard let parameterisedFSM = $0.type.asParameterisedFiniteStateMachine else {
                    return
                }
                parameterisedFSM.suspend()
                if false == $0.isRootFSM {
                    self.promises[parameterisedFSM.name] = (parameterisedFSM, [])
                    return
                }
                let clone = parameterisedFSM.clone()
                clone.restart()
                self.promises[parameterisedFSM.name] = (parameterisedFSM, [PromiseData(fsm: clone, hasFinished: false)])
            }
        }
        var jobs = self.fetchJobs(fromTokens: tokens)
        var finish: Bool = false
        // Run until all machines are finished.
        while (false == jobs.isEmpty && false == STOP && false == finish) {
            finish = true
            var i = 0
            for job in jobs {
                var j = 0
                let machines: Set<Machine> = self.getMachines(fromJob: job)
                machines.forEach { $0.fsm.takeSnapshot() }
                for (fsm, machine) in job {
                    let fsm = self.promises[fsm.name]?.stack.first?.fsm.asScheduleableFiniteStateMachine ?? fsm
                    machine.clock.update(fromFSM: fsm)
                    DEBUG = machine.debug
                    if (true == scheduleHandler.handleUnloadedMachine(fsm)) {
                        jobs[i].remove(at: j)
                        continue
                    }
                    self.invocations = false
                    fsm.next()
                    finish = finish && (fsm.hasFinished || fsm.isSuspended) && (false == self.invocations)
                    if true == fsm.hasFinished, nil != self.promises[fsm.name] {
                        self.promises[fsm.name]?.stack.first?.hasFinished = true
                        self.promises[fsm.name]?.stack.removeFirst()
                        finish = false
                    }
                    j += 1
                }
                machines.forEach { $0.fsm.saveSnapshot() }
                if (true == jobs[i].isEmpty) {
                    jobs.remove(at: i)
                    continue
                }
                i += 1
            }
        }
    }
    
    public func invoke<P: Variables, R>(_ id: FSM_ID, with parameters: P) -> Promise<R> {
        guard let existingPromiseData = self.promises[id] else {
            self.error("Attempting to invoke FSM with id \(id) when it has not been scheduled.")
        }
        guard true == existingPromiseData.stack.isEmpty else {
            self.error("Attempting to invoke FSM with id \(id) when it is already running.")
        }
        return self.handleInvocation(id: id, fsm: existingPromiseData.fsm, with: parameters)
    }
    
    public func invokeSelf<P: Variables, R>(_ id: FSM_ID, with parameters: P) -> Promise<R> {
        guard let existingPromiseData = self.promises[id] else {
            self.error("Attempting to invoke FSM with id \(id) when it has not been scheduled.")
        }
        guard existingPromiseData.stack.count <= self.stackLimit else {
            self.error("Stack Overflow: Attempting to call FSM with id \(id) more times than the current stack limit (\(self.stackLimit)).")
        }
        return self.handleInvocation(id: id, fsm: existingPromiseData.fsm, with: parameters)
    }
    
    fileprivate func handleInvocation<P: Variables, R>(id: FSM_ID, fsm: AnyParameterisedFiniteStateMachine, with parameters: P) -> Promise<R> {
        let promiseData = PromiseData(fsm: fsm.clone(), hasFinished: false)
        promiseData.fsm.parameters(parameters)
        promiseData.fsm.restart()
        self.promises[id]?.stack.insert(promiseData, at: 0)
        self.invocations = true
        return promiseData.makePromise()
    }
    
    private func fetchJobs(fromTokens tokens: [[SchedulerToken]]) -> [[(AnyScheduleableFiniteStateMachine, Machine)]] {
        return tokens.map { tokens in
            tokens.map { token in
                return (token.fsm, token.machine)
            }
        }
    }

    private func getMachines(fromJob job: [(AnyScheduleableFiniteStateMachine, Machine)]) -> Set<Machine> {
        var machines: Set<Machine> = []
        job.forEach {
            machines.insert($1)
        }
        return machines
    }
    
    fileprivate func error(_ str: String) -> Never {
        self.printer.error(str: str)
        exit(EXIT_FAILURE)
    }
    
}

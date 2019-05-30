/*
 * TimeTriggeredScheduler.swift
 * Scheduling
 *
 * Created by Callum McColl on 30/5/19.
 * Copyright © 2019 Callum McColl. All rights reserved.
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

import FSM
import Gateways
import MachineStructure
import MachineLoading
import swiftfsm
import swiftfsm_helpers
import Utilities

/**
 *  Responsible for the execution of machines in a time-triggered parallel
 *  schedule.
 */
public class TimeTriggeredScheduler: Scheduler, VerifiableGatewayDelegator {
    
    public typealias Gateway = StackGateway
    
    fileprivate let dispatchTable: MetaDispatchTable
    
    public var gateway: StackGateway
    
    private let unloader: MachineUnloader
    
    private let scheduleHandler: ScheduleHandler
    
    fileprivate var threadPool: ThreadPool
    
    /**
     *  Create a new `RoundRobinScheduler`.
     *
     *  - Parameter machines: All the `Machine`s that will be executed.
     */
    public init(
        dispatchTable: MetaDispatchTable,
        gateway: StackGateway = StackGateway(),
        unloader: MachineUnloader,
        scheduleHandler: ScheduleHandler
    ) {
        self.dispatchTable = dispatchTable
        self.gateway = gateway
        self.unloader = unloader
        self.scheduleHandler = scheduleHandler
        self.threadPool = ThreadPool(numberOfThreads: dispatchTable.numberOfThreads)
    }
    
    /**
     *  Start executing all machines.
     */
    public func run(_ machines: [Machine]) -> Void {
        self.gateway.stacks = [:]
        machines.forEach { self.addToGateway($0.fsm, dependencies: $0.dependencies, prefix: $0.name
            + ".") }
        let tokenizer = SequentialPerRingletTokenizer()
        let tokens = tokenizer.separate(machines)
        tokens.forEach {
            $0.forEach {
                guard let parameterisedFSM = $0.type.asParameterisedFiniteStateMachine else {
                    return
                }
                parameterisedFSM.suspend()
                let id = self.gateway.id(of: $0.fullyQualifiedName)
                if false == $0.isRootFSM {
                    self.gateway.stacks[id] = []
                    return
                }
                let clone = parameterisedFSM.clone()
                clone.restart()
                self.gateway.stacks[id] = [PromiseData(fsm: clone, hasFinished: false)]
            }
        }
        guard let table = self.fetchTable(fromTokens: tokens) else {
            return
        }
        var finish: Bool = false
        // Run until all machines are finished.
        while (false == STOP && false == finish) {
            finish = true
            let jobs = table.timeslots.map { timeslots in
                return { () -> Void in
                    let cycleStartTime = microseconds()
                    for timeslot in timeslots {
                        let startTime = cycleStartTime + timeslot.startTime
                        let endTime = startTime + timeslot.duration
                        let startSlackTime = startTime - microseconds()
                        if startSlackTime > 0 {
                            microsleep(startSlackTime)
                        }
                        let fsm = self.gateway.stacks[timeslot.task.id]?.first?.fsm.asScheduleableFiniteStateMachine ?? timeslot.task.fsm
                        fsm.takeSnapshot()
                        timeslot.task.machine.clock.update(fromFSM: fsm)
                        DEBUG = timeslot.task.machine.debug
                        if (true == self.scheduleHandler.handleUnloadedMachine(fsm)) {
                            continue
                        }
                        fsm.next()
                        finish = finish && (fsm.hasFinished || fsm.isSuspended)
                        if true == fsm.hasFinished {
                            self.gateway.finish(timeslot.task.id)
                            finish = false
                        }
                        let endSlackTime = endTime - microseconds()
                        if endSlackTime > 0 {
                            microsleep(endSlackTime)
                        }
                        fsm.saveSnapshot()
                    }
                }
            }
            self.threadPool.execute(jobs)
        }
    }
    
    private func fetchTable(fromTokens tokens: [[SchedulerToken]]) -> DispatchTable<Token>? {
        guard let timeslots: [[Timeslot<Token>]] = tokens.failMap({ tokens in
            tokens.failMap { token in
                guard let timeslot = self.dispatchTable.findTimeslot(token.fullyQualifiedName) else {
                    return nil
                }
                let newToken = Token(
                    id: self.gateway.id(of: token.fullyQualifiedName),
                    fsm: token.fsm,
                    machine: token.machine
                )
                return Timeslot<Token>(startTime: timeslot.startTime, duration: timeslot.duration, task: newToken)
            }?.sorted { $0.startTime < $1.startTime }
        }) else {
            return nil
        }
        return DispatchTable<Token>(numberOfThreads: self.dispatchTable.numberOfThreads, timeslots: timeslots)
    }
    
    fileprivate func addToGateway(_ fsm: FSMType, dependencies: [Dependency], prefix: String) {
        let id = self.gateway.id(of: prefix + fsm.name)
        self.gateway.fsms[id] = fsm
        for dependency in dependencies {
            let subprefix = prefix + fsm.name + "."
            switch dependency {
            case .callableParameterisedMachine(let subfsm, let subdependencies):
                switch fsm {
                case .controllableFSM:
                    self.gateway.stacks[id] = []
                default:
                    break
                }
                self.addToGateway(.parameterisedFSM(subfsm), dependencies: subdependencies, prefix: subprefix)
            case .invokableParameterisedMachine(let subfsm, let subdependencies):
                self.addToGateway(.parameterisedFSM(subfsm), dependencies: subdependencies, prefix: subprefix)
            case .submachine(let subfsm, let subdependencies):
                self.addToGateway(.controllableFSM(subfsm), dependencies: subdependencies, prefix: subprefix)
            }
        }
    }
    
    fileprivate struct Token {
        
        var id: FSM_ID
        
        var fsm: AnyScheduleableFiniteStateMachine
        
        var machine: Machine
        
    }
    
}

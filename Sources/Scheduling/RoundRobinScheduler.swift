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

import FSM
import MachineStructure
import MachineLoading

/**
 *  Responsible for the execution of machines.
 */
public class RoundRobinScheduler<Tokenizer: SchedulerTokenizer>: Scheduler where
    Tokenizer.Object == Machine,
    Tokenizer.SchedulerToken == AnyScheduleableFiniteStateMachine
{
    
    // All the machines that will be executed.
    public private(set) var machines: [Machine]

    private let tokenizer: Tokenizer

    private let unloader: MachineUnloader

    private let scheduleHandler: ScheduleHandler
    
    /**
     *  Create a new `RoundRobinScheduler`.
     *
     *  - Parameter machines: All the `Machine`s that will be executed.
     */
    public init(machines: [Machine] = [], tokenizer: Tokenizer, unloader: MachineUnloader, scheduleHandler: ScheduleHandler) {
        self.machines = machines
        self.tokenizer = tokenizer
        self.unloader = unloader
        self.scheduleHandler = scheduleHandler
    }
    
    /**
     *  Start executing all machines.
     */
    public func run() -> Void {
        var jobs = self.tokenizer.separate(self.machines)
        // Run until all machines are finished.
        while (false == jobs.isEmpty && false == STOP) {
            var i = 0
            for job in jobs {
                var j = 0
                let machines: Set<Machine> = self.getMachines(fromJob: job)
                machines.forEach { $0.fsm.takeSnapshot() }
                for (fsm, machine) in job {
                    DEBUG = machine.debug
                    if (true == scheduleHandler.handleUnloadedMachine(fsm)) {
                        jobs[i].remove(at: j)
                        continue
                    }
                    fsm.next()
                    if (true == fsm.hasFinished) {
                        jobs[i].remove(at: j)
                        self.unloader.unload(fsm)
                        continue
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

    private func getMachines(fromJob job: [(AnyScheduleableFiniteStateMachine, Machine)]) -> Set<Machine> {
        var machines: Set<Machine> = []
        job.forEach {
            machines.insert($1)
        }
        return machines
    }
    
}

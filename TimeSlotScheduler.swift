/*
 * TimeSlotScheduler.swift
 * swiftfsm
 *
 * Created by Callum McColl on 10/10/2015.
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

import Darwin
import Swift_FSM

public class TimeSlotScheduler: Scheduler {
    
    private let factory: RunnableMachineFactory
    private var finished: UnsafeMutablePointer<sem_t>
    private var index: Int = 0
    // All the machines that will be executed.
    public private(set) var machines: [RunnableMachine]
    private let time: UInt32
    private let timer: Timer
    
    public init(
        machines: [RunnableMachine] = [],
        time: UInt32 = 15000,
        factory: RunnableMachineFactory,
        timer: Timer
    ) {
        self.machines = machines
        self.finished = sem_open(
            "TSS_finished_" + String(microseconds()),
            O_CREAT,
            0,
            0
        )
        self.time = time
        self.timer = timer
        self.factory = factory
    }
    
    public func addMachine(machine: Machine) {
        machines.append(factory.make(machine))
    }
    
    public func run() {
        if (self.machines.count < 1) {
            return
        }
        self.index = 0
        self.machines[self.index].execute()
        self.timer.delay(self.time, callback: handleTimeslot)
        sem_wait(self.finished)
    }
    
    private func handleTimeslot() {
        if (true == self.machines[index].currentlyRunning) {
            self.timer.stop()
            print("Error: Machine did not finish in time")
            sem_post(self.finished)
            return
        }
        if (true == self.machines[index].machine.hasFinished()) {
            self.machines.removeAtIndex(index--)
            if (self.machines.count < 1) {
                sem_post(self.finished)
                return
            }
        }
        self.index = ++self.index % self.machines.count
        self.machines[index].execute()
        self.timer.delay(self.time, callback: self.handleTimeslot)
    }
    
    deinit {
        sem_close(self.finished)
    }
    
}
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
    
    private let dispatchTable: DispatchTable
    private let factory: RunnableMachineFactory
    private var finished: UnsafeMutablePointer<sem_t>
    private let timer: Timer
    
    public init(
        dispatchTable: DispatchTable,
        factory: RunnableMachineFactory,
        timer: Timer
    ) {
        self.finished = sem_open(
            "TSS_finished_" + String(microseconds()),
            O_CREAT,
            0,
            0
        )
        self.timer = timer
        self.factory = factory
    }
    
    public func run() {
        if (true == self.dispatchTable.empty()) {
            return
        }
        let d: Dispatchable = self.dispatchTable.get()
        d.item.execute()
        self.timer.delay(d.timeout, callback: handleTimeSlot)
        sem_wait(self.finished)
    }
    
    private func handleTimeSlot() {
        let d: Dispatchable = self.dispatchTable.get()
        if (true == d.item.currentlyRunning) {
            self.timer.stop()
            print("Error: Machine did not finish in time")
            sem_post(self.finished)
            return
        }
        if (true == d.item.machine.hasFinished()) {
            self.dispatchTable.remove()
            if (true == self.dispatchTable.empty()) {
                sem_post(self.finished)
                return
            }
        }
        let d2: Dispatchable = self.dispatchTable.next()
        d2.item.execute()
        self.timer.delay(d2.timeout, callback: self.handleTimeSlot)
    }
    
    deinit {
        sem_close(self.finished)
    }
    
}
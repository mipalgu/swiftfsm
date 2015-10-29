/*
 * main.swift
 * swiftfsm
 *
 * Created by Callum McColl on 14/08/2015.
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

print("Hello, when I grow up, I will be a full-blown state machine scheduler!")

// Dynamic Time Slots - task may get more than one timeslot if it is needed.
//let factory: DynamicTimeSlotFactory = DynamicTimeSlotFactory()

// Static Time Slots - each task gets one time slot
let factory: StaticTimeSlotFactory = StaticTimeSlotFactory()

// Load the machines from dylibs.
let loader: MachineLoader = DynamicLibraryMachineLoaderFactory().make()
var items: [Dispatchable] = []
let timeslot: UInt = 15000
for (var i: Int = 1; i < Process.arguments.count; i++) {
    // Create three of the same machine
    for j: UInt in 1 ... 3 {
        // Load the machine from the path
        let machine: FiniteStateMachine? = loader.load(Process.arguments[i])
        if (nil == machine) {
            continue
        }
        items.append(
            factory.make(
                "Ping Pong \(j)",
                machine: machine!,
                startTime: 0,
                time: timeslot * j //15 ms * j
            )
        )
    }
}

// Least Laxity Dispatch Table - reorganize the dispatch table every run through
//let dispatchTable: DispatchTable = LeastLaxityDispatchTable(items: items)

// Static Dispatch Table - order of items never changes
let dispatchTable: DispatchTable = StaticDispatchTable(items: items)

let dispatcher: Dispatcher = ThreadDispatcherFactory().make()

let scheduler: Scheduler = DispatchScheduler(
    dispatcher: dispatcher,
    dispatchTable: dispatchTable
)

// Run the scheduler.
scheduler.run()
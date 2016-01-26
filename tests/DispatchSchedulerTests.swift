/*
 * DispatchSchedulerTests.swift
 * swiftfsm_tests
 *
 * Created by Callum McColl on 26/10/2015.
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

@testable import swiftfsm
import FSM
import XCTest

public class DispatchSchedulerTests: SwiftFSMTestCase {

    
    public override var allTests: [(String, () -> Void)] {
        return [
            ("testSchedulerRunsInTime", testSchedulerRunsInTime)
        ]
    }
    
    private var scheduler: DispatchScheduler!
    
    public override func setUp() {
        self.makeScheduler([getFastPingPongMachine(true)])
    }
    
    private func makeScheduler(machines: [FiniteStateMachine]) {
        var items: [Dispatchable] = []
        var i: UInt = 0
        for fsm: FiniteStateMachine in machines {
            items.append(
                StaticTimeSlotDispatchableItem(
                    item: RunnableMachine(
                        machine: fsm,
                        name: "Ping Pong \(i)",
                        runner: SingleThreadedMachineRunner()
                    ),
                    startTime: 15000 * i,
                    timeout: 15000
                )
            )
            i++
        }
        let dispatcher: Dispatcher = ThreadDispatcher(
            thread: ThreadPool(
                numberOfThreads: 7,
                factory: SingleThreadFactory()
            ),
            timer: Timer(thread: SingleThread())
        )
        let dispatchTable = StaticDispatchTable(items: items)
        self.scheduler = DispatchScheduler(
            dispatcher: dispatcher,
            dispatchTable: dispatchTable
        )
    }
    
    public func testSchedulerRunsInTime() {
        self.scheduler.run()
        XCTAssert(2 == super.counter)
    }
}

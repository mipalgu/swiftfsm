/*
 * ScheduleThreadVariationsTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 18/11/21.
 * Copyright © 2021 Callum McColl. All rights reserved.
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

import XCTest

import KripkeStructure
import swiftfsm
import Timers

@testable import Verification

class ScheduleThreadVariationsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_canGenerateSectionsForSingleMachine() throws {
        let fsm = AnyControllableFiniteStateMachine(ToggleFiniteStateMachine())
        let fsm2 = AnyControllableFiniteStateMachine(ToggleFiniteStateMachine())
        let pool1 = FSMPool(fsms: [.controllableFSM(fsm)])
        let pool2 = FSMPool(fsms: [.controllableFSM(fsm2)])
        let timeslots = [
            Timeslot(
                callChain: CallChain(root: fsm.name, calls: []),
                startingTime: 0,
                duration: 20,
                cyclesExecuted: 0
            )
        ]
        let timeslots2 = [
            Timeslot(
                callChain: CallChain(root: fsm2.name, calls: []),
                startingTime: 0,
                duration: 20,
                cyclesExecuted: 0
            )
        ]
        let sectionVariations = SnapshotSectionVariations(
            pool: pool1,
            section: SnapshotSection(timeslots: timeslots),
            gateway: (fsm.base as! ToggleFiniteStateMachine).gateway,
            timer: (fsm.base as! ToggleFiniteStateMachine).timer,
            cycleLength: 100
        )
        let variations = ScheduleThreadVariations(
            pool: pool2,
            thread: ScheduleThread(sections: [SnapshotSection(timeslots: timeslots2)]),
            gateway: (fsm2.base as! ToggleFiniteStateMachine).gateway,
            timer: (fsm2.base as! ToggleFiniteStateMachine).timer,
            cycleLength: 100
        )
        XCTAssertEqual(variations.pathways.count, sectionVariations.sections.count)
        let sections1 = [[sectionVariations.sections]]
        let sections2 = variations.pathways.map { $0.sections.map(\.sections) }
        XCTAssertEqual(sections2, sections1)
    }
    
    func test_canGenerateSectionsForTwoMachineInSeparateSections() throws {
        let fsm = AnyControllableFiniteStateMachine(ToggleFiniteStateMachine())
        let fsm2 = AnyControllableFiniteStateMachine(ToggleFiniteStateMachine(name: "toggle2"))
        let base = { fsm.base as! ToggleFiniteStateMachine }
        let base2 = { fsm2.base as! ToggleFiniteStateMachine }
        base2().timer = base().timer
        base2().gateway = base().gateway
        let pool = FSMPool(fsms: [.controllableFSM(fsm), .controllableFSM(fsm2)])
        let timeslots = [
            Timeslot(
                callChain: CallChain(root: fsm.name, calls: []),
                startingTime: 0,
                duration: 20,
                cyclesExecuted: 0
            )
        ]
        let timeslots2 = [
            Timeslot(
                callChain: CallChain(root: fsm2.name, calls: []),
                startingTime: 30,
                duration: 20,
                cyclesExecuted: 0
            )
        ]
        let expectedFsm1 = AnyControllableFiniteStateMachine(ToggleFiniteStateMachine())
        expectedFsm1.next()
        let expectedFsm2 = AnyControllableFiniteStateMachine(ToggleFiniteStateMachine(name: "toggle2"))
        expectedFsm2.next()
        let expectedPool1 = FSMPool(fsms: [.controllableFSM(expectedFsm1), .controllableFSM(fsm2)])
        let expectedPool2 = FSMPool(fsms: [.controllableFSM(expectedFsm1), .controllableFSM(expectedFsm2)])
        let expected = ScheduleThreadVariations(pathways: [
            ScheduleThreadPath(sections: [
                SnapshotSectionPath(ringlets: [
                    SnapshotSectionPath.State(
                        previous: [],
                        current: CallAwareRinglet(
                            callChain: CallChain(root: fsm.name, calls: []),
                            ringlet: ConditionalRinglet(
                                fsm: .controllableFSM(expectedFsm1),
                                before: pool,
                                after: expectedPool1,
                                transitioned: false,
                                externalsPreSnapshot: KripkeStatePropertyList(),
                                externalsPostSnapshot: KripkeStatePropertyList(),
                                preSnapshot: KripkeStatePropertyList([
                                    "hasFinished": KripkeStateProperty(type: .Bool, value: true),
                                    "isSuspended": KripkeStateProperty(type: .Bool, value: true),
                                    "value": KripkeStateProperty(type: .Bool, value: false),
                                    "currentState": KripkeStateProperty(type: .String, value: "current")
                                ]),
                                postSnapshot: KripkeStatePropertyList([
                                    "hasFinished": KripkeStateProperty(type: .Bool, value: true),
                                    "isSuspended": KripkeStateProperty(type: .Bool, value: true),
                                    "value": KripkeStateProperty(type: .Bool, value: true),
                                    "currentState": KripkeStateProperty(type: .String, value: "current")
                                ]),
                                calls: [],
                                condition: .lessThanEqual(value: 0)
                            )
                        ),
                        fsm: .controllableFSM(expectedFsm1),
                        cyclesExecuted: 1
                    )
                ]),
                SnapshotSectionPath(ringlets: [
                    SnapshotSectionPath.State(
                        previous: [],
                        current: CallAwareRinglet(
                            callChain: CallChain(root: fsm2.name, calls: []),
                            ringlet: ConditionalRinglet(
                                fsm: .controllableFSM(expectedFsm2),
                                before: expectedPool1,
                                after: expectedPool2,
                                transitioned: false,
                                externalsPreSnapshot: KripkeStatePropertyList(),
                                externalsPostSnapshot: KripkeStatePropertyList(),
                                preSnapshot: KripkeStatePropertyList([
                                    "hasFinished": KripkeStateProperty(type: .Bool, value: true),
                                    "isSuspended": KripkeStateProperty(type: .Bool, value: true),
                                    "value": KripkeStateProperty(type: .Bool, value: false),
                                    "currentState": KripkeStateProperty(type: .String, value: "current")
                                ]),
                                postSnapshot: KripkeStatePropertyList([
                                    "hasFinished": KripkeStateProperty(type: .Bool, value: true),
                                    "isSuspended": KripkeStateProperty(type: .Bool, value: true),
                                    "value": KripkeStateProperty(type: .Bool, value: true),
                                    "currentState": KripkeStateProperty(type: .String, value: "current")
                                ]),
                                calls: [],
                                condition: .greaterThanEqual(value: 30)
                            )
                        ),
                        fsm: .controllableFSM(expectedFsm2),
                        cyclesExecuted: 1
                    )
                ])
            ])
        ])
        let variations = ScheduleThreadVariations(
            pool: pool,
            thread: ScheduleThread(sections: [SnapshotSection(timeslots: timeslots), SnapshotSection(timeslots: timeslots2)]),
            gateway: base().gateway,
            timer: base().timer,
            cycleLength: 100
        )
        XCTAssertEqual(variations, expected)
    }

}

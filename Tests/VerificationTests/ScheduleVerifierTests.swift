/*
 * ScheduleVerifierTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 28/11/21.
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

import Gateways
import KripkeStructureViews
import KripkeStructure
import swiftfsm
import Timers

@testable import Verification

class ScheduleVerifierTests: XCTestCase {
    
    class TestableView: KripkeStructureView {
        
        typealias State = KripkeState
        
        var expected: Set<KripkeState>
        
        private(set) var result: Set<KripkeState>
        
        private(set) var finishCalled: Bool = false
        
        init(expected: Set<KripkeState>) {
            self.expected = expected
            self.result = Set<KripkeState>(minimumCapacity: expected.count)
        }
        
        func commit(state: KripkeState) {
            result.insert(state)
        }

        func finish() {
            finishCalled = true
        }

        func reset(usingClocks: Bool) {
            result.removeAll(keepingCapacity: true)
            finishCalled = false
        }
        
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_canGenerateAllStatesOfSensorFSM() {
        func propertyList(readState: Bool, sensorValue: Bool, currentState: String, previousState: String) -> KripkeStatePropertyList {
            let fsm = SensorFiniteStateMachine()
            fsm.sensors1.val = sensorValue
            if currentState == "initial" {
                fsm.currentState = fsm.initialState
            } else {
                fsm.currentState = EmptyMiPalState(currentState)
            }
            if previousState == "initial" {
                fsm.previousState = fsm.initialState
            } else {
                fsm.previousState = EmptyMiPalState(previousState)
            }
            let fsmProperties = KripkeStatePropertyList(fsm)
            return [
                "fsms": KripkeStateProperty(
                    type: .Compound([
                        fsm.name: KripkeStateProperty(type: .Compound(fsmProperties), value: fsm)
                    ]),
                    value: [fsm.name: fsm]
                ),
                "pc": KripkeStateProperty(type: .String, value: fsm.name + "." + (readState ? currentState : previousState) + "." + (readState ? "R" : "W"))
            ]
        }
        func target(readState: Bool, sensorValue: Bool, currentState: String, previousState: String) -> (Bool, KripkeStatePropertyList) {
            return (!readState, propertyList(readState: readState, sensorValue: sensorValue, currentState: currentState, previousState: previousState))
        }
        func kripkeState(readState: Bool, sensorValue: Bool, currentState: String, previousState: String, targets: [(resetClock: Bool, target: KripkeStatePropertyList)]) -> KripkeState {
            let fsm = SensorFiniteStateMachine()
            let properties = propertyList(readState: readState, sensorValue: sensorValue, currentState: currentState, previousState: previousState)
            let edges = targets.map {
                KripkeEdge(clockName: fsm.name, constraint: nil, resetClock: $0, takeSnapshot: !readState, time: readState ? 30 : 0, target: $1)
            }
            let state = KripkeState(isInitial: previousState == fsm.initialPreviousState.name, properties: properties)
            for edge in edges {
                state.addEdge(edge)
            }
            return state
        }
        let fsm = SensorFiniteStateMachine()
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        let states: Set<KripkeState> = [
            kripkeState(
                readState: true,
                sensorValue: false,
                currentState: initial,
                previousState: previous,
                targets: [
                    (resetClock: false, target: propertyList(readState: false, sensorValue: false, currentState: initial, previousState: initial))
                ]
            ),
            kripkeState(
                readState: false,
                sensorValue: false,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(readState: true, sensorValue: false, currentState: initial, previousState: initial),
                    target(readState: true, sensorValue: true, currentState: initial, previousState: initial)
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: false,
                currentState: initial,
                previousState: initial,
                targets: [
                    (resetClock: false, target: propertyList(readState: false, sensorValue: false, currentState: initial, previousState: initial))
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: true,
                currentState: initial,
                previousState: initial,
                targets: [
                    (resetClock: true, target: propertyList(readState: false, sensorValue: true, currentState: exit, previousState: initial))
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: true,
                currentState: initial,
                previousState: previous,
                targets: [
                    (resetClock: true, target: propertyList(readState: false, sensorValue: true, currentState: exit, previousState: initial))
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: true,
                currentState: exit,
                previousState: initial,
                targets: [
                    (resetClock: false, target: propertyList(readState: false, sensorValue: true, currentState: exit, previousState: exit))
                ]
            ),
            kripkeState(
                readState: false,
                sensorValue: true,
                currentState: exit,
                previousState: exit,
                targets: [
                    (resetClock: false, target: propertyList(readState: true, sensorValue: true, currentState: exit, previousState: exit))
                ]
            )
        ]
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm.name: 30], scheduleLength: 30)
        fsm.gateway = gateway
        fsm.timer = timer
        let cycleDetector = HashTableCycleDetector<KripkeStatePropertyList>()
        let view = TestableView(expected: states)
        let schedule = Schedule(threads: [
            ScheduleThread(sections: [
                SnapshotSection(timeslots: [
                    Timeslot(
                        callChain: CallChain(root: fsm.name, calls: []),
                        startingTime: 0,
                        duration: 30,
                        cyclesExecuted: 0
                    )
                ])
            ])
        ])
        let pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm))])
        let verifier = ScheduleVerifier(schedule: schedule, allFsms: pool)
        verifier.verify(gateway: gateway, timer: timer, view: view, cycleDetector: cycleDetector)
        XCTAssertEqual(view.result, view.expected)
        if view.expected != view.result {
            let missingElements = view.expected.subtracting(view.result)
            print("missing results: \(missingElements)")
            let extraneousElements = view.result.subtracting(view.expected)
            print("extraneous results: \(extraneousElements)")
        }
        XCTAssertTrue(view.finishCalled)
    }

}

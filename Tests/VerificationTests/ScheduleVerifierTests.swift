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
import Foundation
import Timers
import swift_helpers

@testable import Verification

class ScheduleVerifierTests: XCTestCase {
    
    final class TestableViewFactory: KripkeStructureViewFactory {
        
        private let make: (String) -> TestableView
        
        private(set) var createdViews: [TestableView] = []
        
        var lastView: TestableView! {
            createdViews.last!
        }
        
        init(make: @escaping (String) -> TestableView) {
            self.make = make
        }
        
        func make(identifier: String) -> TestableView {
            let view = self.make(identifier)
            createdViews.append(view)
            return view
        }
        
    }
    
    final class TestableView: KripkeStructureView {
        
        typealias State = KripkeState
        
        let identifier: String
        
        let expectedIdentifier: String
        
        var expected: Set<KripkeState>
        
        private(set) var result: Set<KripkeState>
        
        private(set) var finishCalled: Bool = false
        
        init(identifier: String, expectedIdentifier: String, expected: Set<KripkeState>) {
            self.identifier = identifier
            self.expectedIdentifier = expectedIdentifier
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
        
        @discardableResult
        func check(readableName: String) -> Bool {
            XCTAssertEqual(identifier, expectedIdentifier)
            XCTAssertEqual(result, expected)
            if expected != result {
                explain(name: readableName + "_")
            }
            XCTAssertTrue(finishCalled)
            return identifier == expectedIdentifier && result == expected && finishCalled
        }
        
        func explain(name: String = "") {
            guard expected != result else {
                return
            }
            let missingElements = expected.subtracting(result)
            print("missing results: \(missingElements)")
            let extraneousElements = result.subtracting(expected)
            print("extraneous results: \(extraneousElements)")
            let expectedView = GraphVizKripkeStructureView<KripkeState>(filename: "\(name)expected.gv")
            expectedView.reset(usingClocks: true)
            let resultView = GraphVizKripkeStructureView<KripkeState>(filename: "\(name)result.gv")
            resultView.reset(usingClocks: true)
            for state in expected.sorted(by: { $0.properties.description < $1.properties.description }) {
                expectedView.commit(state: state)
            }
            for state in result.sorted(by: { $0.properties.description < $1.properties.description }) {
                resultView.commit(state: state)
            }
            expectedView.finish()
            resultView.finish()
            print("Writing expected to: \(FileManager.default.currentDirectoryPath)/\(name)expected.gv")
            print("Writing result to: \(FileManager.default.currentDirectoryPath)/\(name)result.gv")
        }
        
    }
    
    var readableName: String {
        self.name.dropFirst(2).dropLast().components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        ScheduleThreadVariationsMock.reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_canGenerateSeparateKripkeStructures() {
        let fsm1 = SensorFiniteStateMachine()
        fsm1.name = fsm1.name + "1"
        let fsm1StartingTime: UInt = 10
        let fsm1Duration: UInt = 30
        let fsm2StartingTime: UInt = 50
        let fsm2Duration: UInt = 20
        let cycleLength: UInt = fsm2StartingTime + fsm2Duration
        let states1 = sensorsKripkeStructure(fsmName: fsm1.name, startingTime: 10, duration: fsm1Duration, cycleLength: cycleLength)
        let fsm2 = SensorFiniteStateMachine()
        fsm2.name = fsm2.name + "2"
        let states2 = sensorsKripkeStructure(fsmName: fsm2.name, startingTime: fsm2StartingTime, duration: fsm2Duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm1.name: fsm1Duration, fsm2.name: fsm2Duration], scheduleLength: cycleLength)
        fsm1.gateway = gateway
        fsm1.timer = timer
        fsm2.gateway = gateway
        fsm2.timer = timer
        let cycleDetector = HashTableCycleDetector<KripkeStatePropertyList>()
        let viewFactory = TestableViewFactory {
            switch $0 {
            case fsm1.name:
                return TestableView(identifier: $0, expectedIdentifier: fsm1.name, expected: states1)
            case fsm2.name:
                return TestableView(identifier: $0, expectedIdentifier: fsm2.name, expected: states2)
            default:
                XCTFail("Got incorrect identifier for view: \($0)")
                return TestableView(identifier: "_bad", expectedIdentifier: fsm1.name, expected: [])
            }
        }
        let fsm1Timeslot = Timeslot(
            fsms: [fsm1.name],
            callChain: CallChain(root: fsm1.name, calls: []),
            startingTime: fsm1StartingTime,
            duration: fsm1Duration,
            cyclesExecuted: 0
        )
        let fsm2Timeslot = Timeslot(
            fsms: [fsm2.name],
            callChain: CallChain(root: fsm2.name, calls: []),
            startingTime: fsm2StartingTime,
            duration: fsm2Duration,
            cyclesExecuted: 0
        )
        let fsm1Pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm1))])
        let fsm2Pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm2))])
        let isolator = ScheduleIsolator(
            threads: [
                IsolatedThread(
                    map: VerificationMap(
                        steps: [
                            VerificationMap.Step(
                                time: fsm1Timeslot.startingTime,
                                step: .takeSnapshotAndStartTimeslot(timeslot: fsm1Timeslot)
                            ),
                            VerificationMap.Step(
                                time: fsm1Timeslot.startingTime + fsm1Timeslot.duration,
                                step: .executeAndSaveSnapshot(timeslot: fsm1Timeslot)
                            )
                        ],
                        stepLookup: []
                    ),
                    pool: fsm1Pool
                ),
                IsolatedThread(
                    map: VerificationMap(
                        steps: [
                            VerificationMap.Step(
                                time: fsm2Timeslot.startingTime,
                                step: .takeSnapshotAndStartTimeslot(timeslot: fsm2Timeslot)
                            ),
                            VerificationMap.Step(
                                time: fsm2Timeslot.startingTime + fsm2Timeslot.duration,
                                step: .executeAndSaveSnapshot(timeslot: fsm2Timeslot)
                            )
                        ],
                        stepLookup: []
                    ),
                    pool: fsm2Pool
                )
            ],
            cycleLength: cycleLength
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        verifier.verify(gateway: gateway, timer: timer, viewFactory: viewFactory, cycleDetector: cycleDetector)
        if viewFactory.createdViews.count != 2 {
            XCTFail("Incorrect number of views created: \(viewFactory.createdViews.count)")
            return
        }
        let view1 = viewFactory.createdViews[0]
        let view2 = viewFactory.createdViews[1]
        if !view1.check(readableName: readableName) {
            return
        }
        view2.check(readableName: readableName)
    }
    
    func test_canGenerateCombinedKripkeStructure() {
        let fsm1 = SensorFiniteStateMachine()
        fsm1.name = fsm1.name + "1"
        let fsm1StartingTime: UInt = 10
        let fsm1Duration: UInt = 30
        let fsm2StartingTime: UInt = 50
        let fsm2Duration: UInt = 20
        let cycleLength: UInt = fsm2StartingTime + fsm2Duration
        let fsm2 = SensorFiniteStateMachine()
        fsm2.name = fsm2.name + "2"
        let states = twoSensorKripkeStructure(
            fsm1: (name: fsm1.name, startingTime: fsm1StartingTime, duration: fsm1Duration),
            fsm2: (name: fsm2.name, startingTime: fsm2StartingTime, duration: fsm2Duration),
            cycleLength: cycleLength
        )
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm1.name: fsm1Duration, fsm2.name: fsm2Duration], scheduleLength: cycleLength)
        fsm1.gateway = gateway
        fsm1.timer = timer
        fsm2.gateway = gateway
        fsm2.timer = timer
        let cycleDetector = HashTableCycleDetector<KripkeStatePropertyList>()
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: "0", expected: states)
        }
        let fsm1Timeslot = Timeslot(
            fsms: [fsm1.name],
            callChain: CallChain(root: fsm1.name, calls: []),
            startingTime: fsm1StartingTime,
            duration: fsm1Duration,
            cyclesExecuted: 0
        )
        let fsm2Timeslot = Timeslot(
            fsms: [fsm2.name],
            callChain: CallChain(root: fsm2.name, calls: []),
            startingTime: fsm2StartingTime,
            duration: fsm2Duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(
            fsms: [
                .controllableFSM(AnyControllableFiniteStateMachine(fsm1)),
                .controllableFSM(AnyControllableFiniteStateMachine(fsm2))
            ]
        )
        let isolator = ScheduleIsolator(
            threads: [
                IsolatedThread(
                    map: VerificationMap(
                        steps: [
                            VerificationMap.Step(
                                time: fsm1Timeslot.startingTime,
                                step: .takeSnapshotAndStartTimeslot(timeslot: fsm1Timeslot)
                            ),
                            VerificationMap.Step(
                                time: fsm1Timeslot.startingTime + fsm1Timeslot.duration,
                                step: .executeAndSaveSnapshot(timeslot: fsm1Timeslot)
                            ),
                            VerificationMap.Step(
                                time: fsm2Timeslot.startingTime,
                                step: .takeSnapshotAndStartTimeslot(timeslot: fsm2Timeslot)
                            ),
                            VerificationMap.Step(
                                time: fsm2Timeslot.startingTime + fsm2Timeslot.duration,
                                step: .executeAndSaveSnapshot(timeslot: fsm2Timeslot)
                            )
                        ],
                        stepLookup: []
                    ),
                    pool: pool
                )
            ],
            cycleLength: cycleLength
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        verifier.verify(gateway: gateway, timer: timer, viewFactory: viewFactory, cycleDetector: cycleDetector)
        guard let view = viewFactory.lastView else {
            XCTFail("Incorrect number of views created: \(viewFactory.createdViews.count)")
            return
        }
        view.check(readableName: readableName)
    }
    
    func test_canGenerateAllStatesOfSensorFSM() {
        let fsm = SensorFiniteStateMachine()
        let startingTime: UInt = 10
        let duration: UInt = 30
        let cycleLength = startingTime + duration
        let states = sensorsKripkeStructure(fsmName: fsm.name, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm.name: duration], scheduleLength: cycleLength)
        fsm.gateway = gateway
        fsm.timer = timer
        let cycleDetector = HashTableCycleDetector<KripkeStatePropertyList>()
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: fsm.name, expected: states)
        }
        let timeslot = Timeslot(
            fsms: [fsm.name],
            callChain: CallChain(root: fsm.name, calls: []),
            startingTime: startingTime,
            duration: duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm))])
        let isolator = ScheduleIsolator(
            threads: [
                IsolatedThread(
                    map: VerificationMap(
                        steps: [
                            VerificationMap.Step(
                                time: timeslot.startingTime,
                                step: .takeSnapshotAndStartTimeslot(timeslot: timeslot)
                            ),
                            VerificationMap.Step(
                                time: timeslot.startingTime + timeslot.duration,
                                step: .executeAndSaveSnapshot(timeslot: timeslot)
                            )
                        ],
                        stepLookup: []
                    ),
                    pool: pool
                )
            ],
            cycleLength: timeslot.startingTime + timeslot.duration
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        verifier.verify(gateway: gateway, timer: timer, viewFactory: viewFactory, cycleDetector: cycleDetector)
        guard let view: TestableView = viewFactory.lastView else {
            XCTFail("Failed to create Kripke Structure View.")
            return
        }
        view.check(readableName: readableName)
    }
    
    private func twoSensorKripkeStructure(
        fsm1: (name: String, startingTime: UInt, duration: UInt),
        fsm2: (name: String, startingTime: UInt, duration: UInt),
        cycleLength: UInt
    ) -> Set<KripkeState> {
        let fsm1Name = fsm1.name
        let fsm2Name = fsm2.name
        var statesLookup: [KripkeStatePropertyList: KripkeState] = [:]
        statesLookup.reserveCapacity(64)
        func propertyList(
            executing: String,
            readState: Bool,
            fsm1: (sensorValue: Bool, currentState: String, previousState: String),
            fsm2: (sensorValue: Bool, currentState: String, previousState: String)
        ) -> KripkeStatePropertyList {
            var currentState: String!
            var previousState: String!
            let configurations = [
                (fsm1Name, fsm1.sensorValue, fsm1.currentState, fsm1.previousState),
                (fsm2Name, fsm2.sensorValue, fsm2.currentState, fsm2.previousState)
            ]
            let fsms = configurations.map { (data) -> (String, KripkeStatePropertyList, SensorFiniteStateMachine) in
                let fsm = SensorFiniteStateMachine()
                fsm.name = data.0
                fsm.sensors1.val = data.1
                if data.0 == executing {
                    currentState = data.2
                    previousState = data.3
                }
                if data.2 == "initial" {
                    fsm.currentState = fsm.initialState
                } else {
                    fsm.currentState = EmptyMiPalState(data.2)
                }
                if data.3 == "initial" {
                    fsm.previousState = fsm.initialState
                } else {
                    fsm.previousState = EmptyMiPalState(data.3)
                }
                fsm.ringlet.previousState = fsm.previousState
                fsm.ringlet.shouldExecuteOnEntry = fsm.previousState != fsm.currentState
                let fsmProperties = KripkeStatePropertyList(fsm)
                return (fsm.name, fsmProperties, fsm)
            }
            return [
                "fsms": KripkeStateProperty(
                    type: .Compound(KripkeStatePropertyList(Dictionary<String, KripkeStateProperty>(uniqueKeysWithValues: fsms.map {
                        ($0, KripkeStateProperty(type: .Compound($1), value: $2))
                    }))),
                    value: [fsm.name: fsm]
                ),
                "pc": KripkeStateProperty(type: .String, value: executing + "." + (readState ? currentState! : previousState!) + "." + (readState ? "R" : "W"))
            ]
        }
        func target(
            executing: String,
            readState: Bool,
            resetClock: Bool,
            duration: UInt,
            fsm1: (sensorValue: Bool, currentState: String, previousState: String),
            fsm2: (sensorValue: Bool, currentState: String, previousState: String)
        ) -> (String, Bool, KripkeStatePropertyList, UInt) {
            return (
                executing,
                resetClock,
                propertyList(executing: executing, readState: readState, fsm1: fsm1, fsm2: fsm2),
                duration
            )
        }
        func kripkeState(
            executing: String,
            readState: Bool,
            fsm1: (sensorValue: Bool, currentState: String, previousState: String),
            fsm2: (sensorValue: Bool, currentState: String, previousState: String),
            targets: [(executing: String, resetClock: Bool, target: KripkeStatePropertyList, duration: UInt)]
        ) -> KripkeState {
            let fsm = SensorFiniteStateMachine()
            fsm.name = fsm1Name
            let properties = propertyList(
                executing: executing,
                readState: readState,
                fsm1: fsm1,
                fsm2: fsm2
            )
            let edges = targets.map {
                KripkeEdge(
                    clockName: $0,
                    constraint: nil,
                    resetClock: $1,
                    takeSnapshot: !readState,
                    time: $3,
                    target: $2
                )
            }
            let state = statesLookup[properties] ?? KripkeState(isInitial: fsm1.previousState == fsm.initialPreviousState.name, properties: properties)
            if nil == statesLookup[properties] {
                statesLookup[properties] = state
            }
            for edge in edges {
                state.addEdge(edge)
            }
            return state
        }
        let fsm = SensorFiniteStateMachine()
        fsm.name = fsm1Name
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        let fsm1Gap = fsm2.startingTime - fsm1.duration - fsm1.startingTime
        let fsm2Gap = fsm1.startingTime
        let states: Set<KripkeState> = [
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: previous),
                fsm2: (sensorValue: false, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: previous)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: previous)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: initial, previousState: previous)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: []
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: false, currentState: initial, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: false, currentState: initial, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: initial, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: initial),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                        fsm2: (sensorValue: true, currentState: exit, previousState: exit)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: exit),
                fsm2: (sensorValue: true, currentState: exit, previousState: exit),
                targets: []
            ),
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: initial, previousState: previous),
                fsm2: (sensorValue: false, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.startingTime - (fsm1.startingTime + fsm1.duration),
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: previous)
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: previous)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: initial, previousState: previous)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: false, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: false, currentState: initial, previousState: initial)
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                fsm2: (sensorValue: true, currentState: initial, previousState: previous),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (sensorValue: true, currentState: exit, previousState: initial),
                        fsm2: (sensorValue: true, currentState: exit, previousState: initial)
                    )
                ]
            )
        ]
        return states
    }
    
    private func sensorsKripkeStructure(fsmName: String, startingTime: UInt, duration: UInt, cycleLength: UInt) -> Set<KripkeState> {
        func propertyList(readState: Bool, sensorValue: Bool, currentState: String, previousState: String) -> KripkeStatePropertyList {
            let fsm = SensorFiniteStateMachine()
            fsm.name = fsmName
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
            fsm.ringlet.previousState = fsm.previousState
            fsm.ringlet.shouldExecuteOnEntry = fsm.previousState != fsm.currentState
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
        func target(readState: Bool, resetClock: Bool, sensorValue: Bool, currentState: String, previousState: String) -> (Bool, KripkeStatePropertyList) {
            return (resetClock, propertyList(readState: readState, sensorValue: sensorValue, currentState: currentState, previousState: previousState))
        }
        func kripkeState(readState: Bool, sensorValue: Bool, currentState: String, previousState: String, targets: [(resetClock: Bool, target: KripkeStatePropertyList)]) -> KripkeState {
            let fsm = SensorFiniteStateMachine()
            fsm.name = fsmName
            let properties = propertyList(readState: readState, sensorValue: sensorValue, currentState: currentState, previousState: previousState)
            let edges = targets.map {
                KripkeEdge(clockName: fsm.name, constraint: nil, resetClock: $0, takeSnapshot: !readState, time: readState ? duration : cycleLength - duration, target: $1)
            }
            let state = KripkeState(isInitial: previousState == fsm.initialPreviousState.name, properties: properties)
            for edge in edges {
                state.addEdge(edge)
            }
            return state
        }
        let fsm = SensorFiniteStateMachine()
        fsm.name = fsmName
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
                    target(readState: false, resetClock: false, sensorValue: false, currentState: initial, previousState: initial)
                ]
            ),
            kripkeState(
                readState: false,
                sensorValue: false,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(readState: true, resetClock: false, sensorValue: false, currentState: initial, previousState: initial),
                    target(readState: true, resetClock: false, sensorValue: true, currentState: initial, previousState: initial)
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: false,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(readState: false, resetClock: false, sensorValue: false, currentState: initial, previousState: initial)
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: true,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(readState: false, resetClock: false, sensorValue: true, currentState: exit, previousState: initial)
                ]
            ),
            kripkeState(
                readState: false,
                sensorValue: true,
                currentState: exit,
                previousState: initial,
                targets: [
                    target(readState: true, resetClock: true, sensorValue: true, currentState: exit, previousState: initial)
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: true,
                currentState: initial,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, sensorValue: true, currentState: exit, previousState: initial)
                ]
            ),
            kripkeState(
                readState: true,
                sensorValue: true,
                currentState: exit,
                previousState: initial,
                targets: [
                    target(readState: false, resetClock: false, sensorValue: true, currentState: exit, previousState: exit)
                ]
            ),
            kripkeState(
                readState: false,
                sensorValue: true,
                currentState: exit,
                previousState: exit,
                targets: []
            )
        ]
        return states
    }

}

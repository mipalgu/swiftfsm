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
import swiftfsm_binaries
import SwiftMachines
import MachineStructure

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
        
        func outputViews(name: String) throws {
            let filemanager = FileManager.default
            let currentDirectory = URL(fileURLWithPath: filemanager.currentDirectoryPath, isDirectory: true)
            let buildDirectory = currentDirectory.appendingPathComponent("kripke_structures", isDirectory: true)
            let testDirectory = buildDirectory.appendingPathComponent(name, isDirectory: true)
            defer {
                filemanager.changeCurrentDirectoryPath(currentDirectory.path)
            }
            _ = try? filemanager.removeItem(atPath: testDirectory.path)
            guard
                let _ = try? filemanager.createDirectory(at: testDirectory, withIntermediateDirectories: true),
                true == filemanager.changeCurrentDirectoryPath(testDirectory.path)
            else {
                fatalError("Unable to create views directory")
            }
            for view in createdViews {
                let outputView = GraphVizKripkeStructureView(filename: view.identifier + ".gv")
                let nusmvView = NuSMVKripkeStructureView(identifier: view.identifier)
                try outputView.generate(store: view.store, usingClocks: true)
                try nusmvView.generate(store: view.store, usingClocks: true)
            }
        }
        
    }
    
    final class TestableView: KripkeStructureView {
        
        typealias State = KripkeState
        
        let identifier: String
        
        let expectedIdentifier: String
        
        var expected: Set<KripkeState>

        private(set) var store: KripkeStructure! = nil
        
        private(set) var result: Set<KripkeState>
        
        init(identifier: String, expectedIdentifier: String, expected: Set<KripkeState>) {
            self.identifier = identifier
            self.expectedIdentifier = expectedIdentifier
            self.expected = expected
            self.result = Set<KripkeState>(minimumCapacity: expected.count)
        }

        func generate(store: KripkeStructure, usingClocks: Bool) throws {
            self.store = store
            self.result = try Set(store.states)
        }
        
        @discardableResult
        func check(readableName: String) throws -> Bool {
            XCTAssertEqual(result, expected)
            if expected != result {
                try explain(name: readableName + "_")
            }
            XCTAssertEqual(identifier, expectedIdentifier)
            return identifier == expectedIdentifier && result == expected
        }
        
        func explain(name: String = "") throws {
            guard expected != result else {
                return
            }
            let missingElements = expected.subtracting(result)
            print("missing results: \(missingElements)")
            let extraneousElements = result.subtracting(expected)
            print("extraneous results: \(extraneousElements)")
            let expectedView = GraphVizKripkeStructureView(filename: "\(name)expected.gv")
            let resultView = GraphVizKripkeStructureView(filename: "\(name)result.gv")
            let expectedStore = try InMemoryKripkeStructure(identifier: expectedIdentifier, states: expected)
            try expectedView.generate(store: expectedStore, usingClocks: true)
            try resultView.generate(store: store, usingClocks: true)
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

    func test_canEncodeAndDecodeKripkeStatePropertyList() {
        let fsm = ExternalsFiniteStateMachine()
        let propertyList = KripkeStatePropertyList(fsm)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        do {
            let encoded = try encoder.encode(propertyList)
            let decoded = try decoder.decode(KripkeStatePropertyList.self, from: encoded)
            XCTAssertEqual(propertyList, decoded)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_canGenerateSeparateKripkeStructures() {
        separateSensors { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                if viewFactory.createdViews.count != 2 {
                    XCTFail("Incorrect number of views created: \(viewFactory.createdViews.count)")
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                let view1 = viewFactory.createdViews[0]
                let view2 = viewFactory.createdViews[1]
                if try !view1.check(readableName: self.readableName) {
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view2.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_canGenerateCombinedKripkeStructure() {
        combinedSensors { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                XCTAssertEqual(viewFactory.createdViews.count, 1)
                guard let view = viewFactory.lastView else {
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_canGenerateAllStatesOfSensorFSM() {
        singleSensor { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                guard let view: TestableView = viewFactory.lastView else {
                    XCTFail("Failed to create Kripke Structure View.")
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_canGenerateCombinedTimedKripkeStructure() {
        combinedTimed { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                XCTAssertEqual(viewFactory.createdViews.count, 1)
                guard let view = viewFactory.lastView else {
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_canGenerateSeparateTimedKripkeStructures() {
        separateTimed { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                try viewFactory.outputViews(name: self.readableName)
                if viewFactory.createdViews.count != 2 {
                    XCTFail("Incorrect number of views created: \(viewFactory.createdViews.count)")
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                let view1 = viewFactory.createdViews[0]
                let view2 = viewFactory.createdViews[1]
                if try !view1.check(readableName: self.readableName) {
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view2.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_canGenerateAllStatesOfTimeFSM() {
        singleTime { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                try viewFactory.outputViews(name: self.readableName)
                guard let view: TestableView = viewFactory.lastView else {
                    XCTFail("Failed to create Kripke Structure View.")
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_canGenerateParameterisedCall() {
        delegateSync { (verifier, gateway, timer, kripkeFactory, viewFactory) in
            do {
                try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory).forEach {
                    try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
                }
                guard let view: TestableView = viewFactory.createdViews.first(where: { $0.identifier == "DelegateSyncFiniteStateMachine" }) else {
                    XCTFail("Failed to create Kripke Structure View.")
                    try viewFactory.outputViews(name: self.readableName)
                    return
                }
                try view.check(readableName: self.readableName)
                try viewFactory.outputViews(name: self.readableName)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_measureFourSeparateTime() {
        multipleSeparateSensors(4) { (verifier, gateway, timer, kripkeFactory, _) in
            measure {
                do {
                    _ = try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func test_measureFourCombinedTime() {
        multipleCombinedSensors(4) { (verifier, gateway, timer, kripkeFactory, _) in
            measure {
                do {
                    _ = try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func test_measureCombinedTime() {
        combinedSensors { (verifier, gateway, timer, kripkeFactory, _) in
            measure {
                do {
                    _ = try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func test_measureSeparateTime() {
        separateSensors { (verifier, gateway, timer, kripkeFactory, _) in
            measure {
                do {
                    _ = try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func test_measureSensorTime() {
        singleSensor { (verifier, gateway, timer, kripkeFactory, _) in
            measure {
                do {
                    _ = try verifier.verify(gateway: gateway, timer: timer, factory: kripkeFactory)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    private func delegateSync<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm = DelegateFiniteStateMachine()
        let factory: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
            guard let value = $0["value"] as? Int else {
                fatalError("Unable to fetch value from parameters")
            }
            let fsm = CalleeFiniteStateMachine()
            fsm.parameters.vars.value = value
            return AnyParameterisedFiniteStateMachine(fsm, newMachine: { _ in fatalError("Should never be called") })
        }
        let callee = AnyParameterisedFiniteStateMachine(CalleeFiniteStateMachine(), newMachine: factory)
        let startingTime: UInt = 10
        let duration: UInt = 30
        let cycleLength = startingTime + duration
        let states = delegateSyncKripkeStructure(fsmName: fsm.name, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let calleeId = gateway.id(of: callee.name)
        gateway.stacks[calleeId] = []
        let timer = FSMClock(ringletLengths: [fsm.name: duration, callee.name: duration], scheduleLength: cycleLength)
        fsm.gateway = gateway
        fsm.timer = timer
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: fsm.name, expected: states)
        }
        let timeslot = Timeslot(
            fsms: [fsm.name, callee.name],
            callChain: CallChain(root: fsm.name, calls: []),
            externalDependencies: [],
            startingTime: startingTime,
            duration: duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm)), .parameterisedFSM(callee)], parameterisedFSMs: [callee.name])
        let calleePool = FSMPool(fsms: [.parameterisedFSM(callee)], parameterisedFSMs: [])
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
                        delegates: [callee.name]
                    ),
                    pool: pool
                )
            ],
            parameterisedThreads: [
                callee.name: IsolatedThread(
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
                        delegates: []
                    ),
                    pool: calleePool
                )
            ],
            cycleLength: timeslot.startingTime + timeslot.duration
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func combinedTimed<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm1 = SimpleTimeConditionalFiniteStateMachine()
        fsm1.name = fsm1.name + "1"
        let fsm1StartingTime: UInt = 10
        let fsm1Duration: UInt = 30
        let fsm2StartingTime: UInt = 50
        let fsm2Duration: UInt = 20
        let cycleLength: UInt = fsm2StartingTime + fsm2Duration
        let fsm2 = SimpleTimeConditionalFiniteStateMachine()
        fsm2.name = fsm2.name + "2"
        let states = twoTimeKripkeStructures(
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
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: "0", expected: states)
        }
        let fsm1Timeslot = Timeslot(
            fsms: [fsm1.name],
            callChain: CallChain(root: fsm1.name, calls: []),
            externalDependencies: [],
            startingTime: fsm1StartingTime,
            duration: fsm1Duration,
            cyclesExecuted: 0
        )
        let fsm2Timeslot = Timeslot(
            fsms: [fsm2.name],
            callChain: CallChain(root: fsm2.name, calls: []),
            externalDependencies: [],
            startingTime: fsm2StartingTime,
            duration: fsm2Duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(
            fsms: [
                .controllableFSM(AnyControllableFiniteStateMachine(fsm1)),
                .controllableFSM(AnyControllableFiniteStateMachine(fsm2))
            ],
            parameterisedFSMs: []
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
                        delegates: []
                    ),
                    pool: pool
                )
            ],
            parameterisedThreads: [:],
            cycleLength: cycleLength
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func separateTimed<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm1 = SimpleTimeConditionalFiniteStateMachine()
        fsm1.name = fsm1.name + "1"
        let fsm1StartingTime: UInt = 10
        let fsm1Duration: UInt = 30
        let fsm2StartingTime: UInt = 50
        let fsm2Duration: UInt = 20
        let cycleLength: UInt = fsm2StartingTime + fsm2Duration
        let states1 = timeKripkeStructure(fsmName: fsm1.name, startingTime: 10, duration: fsm1Duration, cycleLength: cycleLength)
        let fsm2 = SimpleTimeConditionalFiniteStateMachine()
        fsm2.name = fsm2.name + "2"
        let states2 = timeKripkeStructure(fsmName: fsm2.name, startingTime: fsm2StartingTime, duration: fsm2Duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm1.name: fsm1Duration, fsm2.name: fsm2Duration], scheduleLength: cycleLength)
        fsm1.gateway = gateway
        fsm1.timer = timer
        fsm2.gateway = gateway
        fsm2.timer = timer
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
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
            externalDependencies: [],
            startingTime: fsm1StartingTime,
            duration: fsm1Duration,
            cyclesExecuted: 0
        )
        let fsm2Timeslot = Timeslot(
            fsms: [fsm2.name],
            callChain: CallChain(root: fsm2.name, calls: []),
            externalDependencies: [],
            startingTime: fsm2StartingTime,
            duration: fsm2Duration,
            cyclesExecuted: 0
        )
        let fsm1Pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm1))], parameterisedFSMs: [])
        let fsm2Pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm2))], parameterisedFSMs: [])
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
                        delegates: []
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
                        delegates: []
                    ),
                    pool: fsm2Pool
                )
            ],
            parameterisedThreads: [:],
            cycleLength: cycleLength
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func separateSensors<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm1 = SensorFiniteStateMachine()
        fsm1.name = fsm1.name + "0"
        let fsm1StartingTime: UInt = 10
        let fsm1Duration: UInt = 30
        let fsm2StartingTime: UInt = 50
        let fsm2Duration: UInt = 20
        let cycleLength: UInt = fsm2StartingTime + fsm2Duration
        let states1 = sensorsKripkeStructure(fsmName: fsm1.name, startingTime: 10, duration: fsm1Duration, cycleLength: cycleLength)
        let fsm2 = SensorFiniteStateMachine()
        fsm2.name = fsm2.name + "1"
        let states2 = sensorsKripkeStructure(fsmName: fsm2.name, startingTime: fsm2StartingTime, duration: fsm2Duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm1.name: fsm1Duration, fsm2.name: fsm2Duration], scheduleLength: cycleLength)
        fsm1.gateway = gateway
        fsm1.timer = timer
        fsm2.gateway = gateway
        fsm2.timer = timer
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
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
            externalDependencies: [],
            startingTime: fsm1StartingTime,
            duration: fsm1Duration,
            cyclesExecuted: 0
        )
        let fsm2Timeslot = Timeslot(
            fsms: [fsm2.name],
            callChain: CallChain(root: fsm2.name, calls: []),
            externalDependencies: [],
            startingTime: fsm2StartingTime,
            duration: fsm2Duration,
            cyclesExecuted: 0
        )
        let fsm1Pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm1))], parameterisedFSMs: [])
        let fsm2Pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm2))], parameterisedFSMs: [])
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
                        delegates: []
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
                        delegates: []
                    ),
                    pool: fsm2Pool
                )
            ],
            parameterisedThreads: [:],
            cycleLength: cycleLength
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func multipleSensors<T>(_ number: Int, use: ([(Timeslot, SensorFiniteStateMachine)], UInt, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsms = (0..<number).map { (i: Int) -> (SensorFiniteStateMachine, UInt, UInt) in
            let fsm = SensorFiniteStateMachine()
            fsm.name += "\(i)"
            return (fsm, UInt(i * 30 + 10), UInt(25))
        }
        guard let last = fsms.last else {
            fatalError("Attempting to create multiple separate sensors with no fsms.")
        }
        let cycleLength: UInt = last.1 + last.2
        let ringletLengths = Dictionary(uniqueKeysWithValues: fsms.map {
            ($0.name, $2)
        })
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: ringletLengths, scheduleLength: cycleLength)
        for (fsm, _, _) in fsms {
            fsm.gateway = gateway
            fsm.timer = timer
        }
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: "0", expected: [])
        }
        let timeslots: [(Timeslot, SensorFiniteStateMachine)] = fsms.map {
            let timeslot = Timeslot(
                fsms: [$0.name],
                callChain: CallChain(root: $0.name, calls: []),
                externalDependencies: [],
                startingTime: $1,
                duration: $2,
                cyclesExecuted: 0
            )
            return (timeslot, $0)
        }
        return use(timeslots, cycleLength, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func multipleSeparateSensors<T>(_ number: Int, _ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        multipleSensors(number) { (timeslots, cycleLength, gateway, timer, kripkeFactory, viewFactory) in
            let threads = timeslots.map {
                IsolatedThread(
                    map: VerificationMap(
                        steps: [
                            VerificationMap.Step(
                                time: $0.startingTime,
                                step: .takeSnapshotAndStartTimeslot(timeslot: $0)
                            ),
                            VerificationMap.Step(
                                time: $0.startingTime + $0.duration,
                                step: .executeAndSaveSnapshot(timeslot: $0)
                            )
                        ],
                        delegates: []
                    ),
                    pool: FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine($1))], parameterisedFSMs: [])
                )
            }
            let isolator = ScheduleIsolator(threads: threads, parameterisedThreads: [:], cycleLength: cycleLength)
            let verifier = ScheduleVerifier(isolatedThreads: isolator)
            return make(verifier, gateway, timer, kripkeFactory, viewFactory)
        }
    }
    
    private func multipleCombinedSensors<T>(_ number: Int, _ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        multipleSensors(number) { (timeslots, cycleLength, gateway, timer, kripkeFactory, viewFactory) in
            let pool = FSMPool(
                fsms: timeslots.map {
                    .controllableFSM(AnyControllableFiniteStateMachine($1))
                },
                parameterisedFSMs: []
            )
            let steps = timeslots.flatMap {
                [
                    VerificationMap.Step(
                        time: $0.0.startingTime,
                        step: .takeSnapshotAndStartTimeslot(timeslot: $0.0)
                    ),
                    VerificationMap.Step(
                        time: $0.0.startingTime + $0.0.duration,
                        step: .executeAndSaveSnapshot(timeslot: $0.0)
                    )
                ]
            }
            let isolator = ScheduleIsolator(
                threads: [
                    IsolatedThread(
                        map: VerificationMap(
                            steps: steps,
                            delegates: []
                        ),
                        pool: pool
                    )
                ],
                parameterisedThreads: [:],
                cycleLength: cycleLength
            )
            let verifier = ScheduleVerifier(isolatedThreads: isolator)
            return make(verifier, gateway, timer, kripkeFactory, viewFactory)
        }
    }
    
    private func combinedSensors<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm1 = SensorFiniteStateMachine()
        fsm1.name = fsm1.name + "0"
        let fsm1StartingTime: UInt = 10
        let fsm1Duration: UInt = 30
        let fsm2StartingTime: UInt = 50
        let fsm2Duration: UInt = 20
        let cycleLength: UInt = fsm2StartingTime + fsm2Duration
        let fsm2 = SensorFiniteStateMachine()
        fsm2.name = fsm2.name + "1"
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
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: "0", expected: states)
        }
        let fsm1Timeslot = Timeslot(
            fsms: [fsm1.name],
            callChain: CallChain(root: fsm1.name, calls: []),
            externalDependencies: [],
            startingTime: fsm1StartingTime,
            duration: fsm1Duration,
            cyclesExecuted: 0
        )
        let fsm2Timeslot = Timeslot(
            fsms: [fsm2.name],
            callChain: CallChain(root: fsm2.name, calls: []),
            externalDependencies: [],
            startingTime: fsm2StartingTime,
            duration: fsm2Duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(
            fsms: [
                .controllableFSM(AnyControllableFiniteStateMachine(fsm1)),
                .controllableFSM(AnyControllableFiniteStateMachine(fsm2))
            ],
            parameterisedFSMs: []
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
                        delegates: []
                    ),
                    pool: pool
                )
            ],
            parameterisedThreads: [:],
            cycleLength: cycleLength
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func singleSensor<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm = SensorFiniteStateMachine()
        fsm.name += "0"
        let startingTime: UInt = 10
        let duration: UInt = 30
        let cycleLength = startingTime + duration
        let states = sensorsKripkeStructure(fsmName: fsm.name, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm.name: duration], scheduleLength: cycleLength)
        fsm.gateway = gateway
        fsm.timer = timer
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: fsm.name, expected: states)
        }
        let timeslot = Timeslot(
            fsms: [fsm.name],
            callChain: CallChain(root: fsm.name, calls: []),
            externalDependencies: [],
            startingTime: startingTime,
            duration: duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm))], parameterisedFSMs: [])
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
                        delegates: []
                    ),
                    pool: pool
                )
            ],
            parameterisedThreads: [:],
            cycleLength: timeslot.startingTime + timeslot.duration
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func singleTime<T>(_ make: (ScheduleVerifier<ScheduleIsolator>, StackGateway, FSMClock, SQLiteKripkeStructureFactory, TestableViewFactory) -> T) -> T {
        let fsm = SimpleTimeConditionalFiniteStateMachine()
        let startingTime: UInt = 10
        let duration: UInt = 30
        let cycleLength = startingTime + duration
        let states = timeKripkeStructure(fsmName: fsm.name, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
        let gateway = StackGateway()
        let timer = FSMClock(ringletLengths: [fsm.name: duration], scheduleLength: cycleLength)
        fsm.gateway = gateway
        fsm.timer = timer
        let kripkeFactory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        let viewFactory = TestableViewFactory {
            TestableView(identifier: $0, expectedIdentifier: fsm.name, expected: states)
        }
        let timeslot = Timeslot(
            fsms: [fsm.name],
            callChain: CallChain(root: fsm.name, calls: []),
            externalDependencies: [],
            startingTime: startingTime,
            duration: duration,
            cyclesExecuted: 0
        )
        let pool = FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(fsm))], parameterisedFSMs: [])
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
                        delegates: []
                    ),
                    pool: pool
                )
            ],
            parameterisedThreads: [:],
            cycleLength: timeslot.startingTime + timeslot.duration
        )
        let verifier = ScheduleVerifier(isolatedThreads: isolator)
        return make(verifier, gateway, timer, kripkeFactory, viewFactory)
    }
    
    private func twoSensorKripkeStructure(
        fsm1: (name: String, startingTime: UInt, duration: UInt),
        fsm2: (name: String, startingTime: UInt, duration: UInt),
        cycleLength: UInt
    ) -> Set<KripkeState> {
        var structure = SensorKripkeStructure()
        return structure.two(fsm1: fsm1, fsm2: fsm2, cycleLength: cycleLength)
    }
    
    private func sensorsKripkeStructure(fsmName: String, startingTime: UInt, duration: UInt, cycleLength: UInt) -> Set<KripkeState> {
        var structure = SensorKripkeStructure()
        structure.names[0] = fsmName
        return structure.single(name: fsmName, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
    }
    
    private func delegateSyncKripkeStructure(
        fsmName: String,
        startingTime: UInt,
        duration: UInt,
        cycleLength: UInt
    ) -> Set<KripkeState> {
        var structure = SyncDelegateKripkeStructure()
        return structure.single(name: fsmName, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
    }
    
    private func timeKripkeStructure(
        fsmName: String,
        startingTime: UInt,
        duration: UInt,
        cycleLength: UInt
    ) -> Set<KripkeState> {
        var structure = TimedKripkeStructure()
        return structure.single(name: fsmName, startingTime: startingTime, duration: duration, cycleLength: cycleLength)
    }
    
    private func twoTimeKripkeStructures(
        fsm1: (name: String, startingTime: UInt, duration: UInt),
        fsm2: (name: String, startingTime: UInt, duration: UInt),
        cycleLength: UInt
    ) -> Set<KripkeState> {
        var structure = TimedKripkeStructure()
        return structure.two(fsm1: fsm1, fsm2: fsm2, cycleLength: cycleLength)
    }

}

/*
 * VerificationCycleKripkeStructureGeneratorTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 19/10/20.
 * Copyright © 2020 Callum McColl. All rights reserved.
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

import KripkeStructure
import KripkeStructureViews
@testable import VerificationOld
import Gateways
import MachineStructure
import Timers
import swiftfsm

import XCTest

public final class VerificationCycleKripkeStructureGeneratorTests: VerificationTestCase, VerificationTokenExecuterDelegate {
    
    static var allTests: [(String, (VerificationCycleKripkeStructureGeneratorTests) -> () throws -> Void)] {
        return [
            ("test_canSpinExternalVariables", test_canSpinExternalVariables)
        ]
    }
    
    private typealias Generator = VerificationCycleKripkeStructureGenerator<
        AggregateCloner<Cloner<KripkeStatePropertyListConverter>>,
        MultipleExternalsSpinnerConstructor<ExternalsSpinnerConstructor<SpinnerRunner>>
    >
    
    private var generator: Generator!
    private var gateway: StackGateway!
    private var cycleDetectorData: HashTableCycleDetector<KripkeStatePropertyList>.Data!
    let cycleDetector = HashTableCycleDetector<KripkeStatePropertyList>()
    let view = AggregateKripkeStructureView<KripkeState>(views: [])
    
    var token: VerificationToken {
        let fsm = AnyControllableFiniteStateMachine(TempFiniteStateMachine())
        let fsmID = gateway.id(of: fsm.name)
        let fsmType = FSMType.controllableFSM(fsm)
        gateway.fsms[fsmID] = fsmType
        let machine = Machine(debug: false, name: "test", fsm: fsmType, clock: FSMClock(ringletLengths: [fsm.name: 0], scheduleLength: 0))
        let boolSpinner: Spinners.Spinner<Bool> = { $0 ? nil : true }
        let externalsData = fsm.externalVariables.map {
            ExternalVariablesVerificationData(
                externalVariables: $0,
                defaultValues: KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: false)]),
                spinners: ["value": { boolSpinner($0 as! Bool) } ]
            )
        }
        let sensorsData = fsm.sensors.map {
            ExternalVariablesVerificationData(
                externalVariables: $0,
                defaultValues: KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: false)]),
                spinners: ["value": { boolSpinner($0 as! Bool) } ]
            )
        }
        let actuatorData = fsm.actuators.map {
            ExternalVariablesVerificationData(
                externalVariables: $0,
                defaultValues: KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: false)]),
                spinners: ["value": { boolSpinner($0 as! Bool) } ]
            )
        }
        return VerificationToken.verify(data: VerificationToken.Data(
            id: fsmID,
            fsm: fsmType,
            machine: machine,
            externalVariables: externalsData,
            sensors: sensorsData,
            actuators: actuatorData,
            parameterisedMachines: [:],
            timeData: nil,
            clockName: fsm.name,
            lastFSMStateName: nil
        ))
    }
    
    var state: VerificationState<HashTableCycleDetector<KripkeStatePropertyList>.Data, StackGateway.GatewayData> {
        return VerificationState(
            initial: true,
            cycleCache: self.cycleDetectorData,
            foundCycle: false,
            tokens: [[self.token]],
            executing: 0,
            lastState: nil,
            lastRecords: [],
            runs: 0,
            callStack: [:],
            results: [:],
            foundResult: false,
            gatewayData: gateway.gatewayData
        )
    }
    
    public override func setUp() {
        self.generator = VerificationCycleKripkeStructureGeneratorFactory().make()
        self.gateway = StackGateway()
        self.cycleDetectorData = self.cycleDetector.initialData
    }
    
    public func test_canSpinExternalVariables() {
        let runs = self.generator.generate(
            fromState: self.state,
            usingCycleDetector: self.cycleDetector,
            usingGateway: self.gateway,
            storingKripkeStructureIn: self.view,
            checkingForCyclesWith: &self.cycleDetectorData,
            callingParameterisedMachines: [:],
            withParameterisedResults: [:],
            storingResultsFor: nil,
            handledAllResults: false,
            tokenExecuterDelegate: self
        )
        let expected = [
            ([false, false], [false, false], [false, false]),
            ([false, false], [false, true], [false, false]),
            ([false, false], [true, false], [false, false]),
            ([false, true], [false, false], [false, false]),
            ([true, false], [false, false], [false, false]),
            ([false, false], [true, true], [false, false]),
            ([false, true], [false, true], [false, false]),
            ([true, false], [false, true], [false, false]),
            ([false, true], [true, false], [false, false]),
            ([true, false], [true, false], [false, false]),
            ([true, true], [false, false], [false, false]),
            ([false, true], [true, true], [false, false]),
            ([true, false], [true, true], [false, false]),
            ([true, true], [false, true], [false, false]),
            ([true, true], [true, false], [false, false]),
            ([true, true], [true, true], [false, false]),
        ]
        let results: [([Bool], [Bool], [Bool])] = runs.enumerated().flatMap { (offset, run) -> [([Bool], [Bool], [Bool])] in
            run.tokens.flatMap { (tokens) -> [([Bool], [Bool], [Bool])] in
                let externals = tokens.map { (token) -> [Bool] in
                    XCTAssertNotNil(token.data)
                    guard let data = token.data else {
                        return []
                    }
                    return data.fsm.externalVariables.map {
                        guard let bool = $0.val as? Bool else {
                            XCTFail("val must be a bool")
                            return false
                        }
                        return bool
                    }
                }
                let sensors = tokens.map { (token) -> [Bool] in
                    XCTAssertNotNil(token.data)
                    guard let data = token.data else {
                        return []
                    }
                    return data.fsm.sensors.map {
                        guard let bool = $0.val as? Bool else {
                            XCTFail("val must be a bool")
                            return false
                        }
                        return bool
                    }
                }
                let actuators = tokens.map { (token) -> [Bool] in
                    XCTAssertNotNil(token.data)
                    guard let data = token.data else {
                        return []
                    }
                    return data.fsm.actuators.map {
                        guard let bool = $0.val as? Bool else {
                            XCTFail("val must be a bool")
                            return false
                        }
                        return bool
                    }
                }
                XCTAssertEqual(externals.count, sensors.count)
                XCTAssertEqual(externals.count, actuators.count)
                guard externals.count == sensors.count, sensors.count == actuators.count else {
                    return []
                }
                return externals.indices.map {
                    (externals[$0], sensors[$0], actuators[$0])
                }
            }
        }
        XCTAssertEqual(runs.count, expected.count)
        XCTAssertEqual(results.map { $0.0 }, expected.map { $0.0 })
        XCTAssertEqual(results.map { $0.1 }, expected.map { $0.1 })
        XCTAssertEqual(results.map { $0.2 }, expected.map { $0.2 })
    }
    
    public func scheduleInfo(of: FSM_ID, caller: FSM_ID, inGateway: ModifiableFSMGateway) -> ParameterisedMachineData {
        fatalError("bad")
    }
    
    public func shouldInclude(call: CallData, forCaller: FSM_ID) -> Bool {
        fatalError("bad")
    }
    
    public func shouldInline(call: CallData, caller: FSM_ID) -> Bool {
        fatalError("bad")
    }
    
}

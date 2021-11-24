/*
 * TimeAwareRingletTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 16/2/21.
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

@testable import Verification

class TimeAwareRingletTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_computesAllPossibleRinglets() throws {
        let fsm = TimeConditionalFiniteStateMachine()
        let id = fsm.gateway.id(of: fsm.name)
        let newMachine: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
            let tempFSM = AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: { _ in fatalError("Should never be called.") })
            let result = tempFSM.parametersFromDictionary($0)
            if result == false {
                fatalError("Unable to call fsm with parameters \($0)")
            }
            return tempFSM
        }
        let controllableFSM: FSMType = .controllableFSM(AnyControllableFiniteStateMachine(fsm))
        fsm.gateway.fsms[id] = .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))
        fsm.gateway.stacks[id] = []
        let ringlets = TimeAwareRinglets(fsm: controllableFSM, gateway: fsm.gateway, timer: fsm.timer, startingTime: 0)
        let falseProperties = KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: Bool(false))])
        let trueProperties = KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: Bool(true))])
        let time: UInt = 2000000
        let pool: (Bool, Bool?) -> FSMPool = {
            if let parameter = $1 {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(parameterValue: parameter), newMachine: newMachine))])
            } else {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))])
            }
        }
        let expectedData: [(Bool, [Bool], Constraint<UInt>)] = [
            (true, [], .lessThanEqual(value: time)),
            (false, [true], .and(lhs: .greaterThan(value: time), rhs: .lessThanEqual(value: 4000000))),
            (false, [true, false], .greaterThan(value: 4000000))
        ]
        let expected: [ConditionalRinglet] = expectedData.map {
            ConditionalRinglet(
                fsm: controllableFSM,
                before: pool(false, nil),
                after: pool($0.0, $0.1.last),
                transitioned: false,
                externalsPreSnapshot: KripkeStatePropertyList(),
                externalsPostSnapshot: KripkeStatePropertyList(),
                preSnapshot: falseProperties,
                postSnapshot: $0.0 ? trueProperties : falseProperties,
                calls: $0.1.map {
                    Call(
                        caller: id,
                        callee: id,
                        parameters: ["value": $0],
                        method: .synchronous,
                        fsm: newMachine(["value": $0]).name
                    )
                },
                condition: $0.2
            )
        }
        XCTAssertEqual(ringlets.ringlets.count, expected.count)
        for (result, expected) in zip(ringlets.ringlets, expected) {
            XCTAssertEqual(result.preSnapshot["value"], expected.preSnapshot["value"])
            XCTAssertEqual(result.postSnapshot["value"], expected.postSnapshot["value"])
            XCTAssertEqual(result.calls, expected.calls)
            XCTAssertEqual(result.condition, expected.condition)
        }
    }
    
    func test_computesAllPossibleRingletsForMiddleStartingTime() throws {
        let fsm = TimeConditionalFiniteStateMachine()
        let id = fsm.gateway.id(of: fsm.name)
        let newMachine: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
            let tempFSM = AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: { _ in fatalError("Should never be called.") })
            let result = tempFSM.parametersFromDictionary($0)
            if result == false {
                fatalError("Unable to call fsm with parameters \($0)")
            }
            return tempFSM
        }
        fsm.gateway.fsms[id] = .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))
        fsm.gateway.stacks[id] = []
        let time: UInt = 3500000
        let ringlets = TimeAwareRinglets(fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)), gateway: fsm.gateway, timer: fsm.timer, startingTime: time)
        let falseProperties = KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: Bool(false))])
        let pool: (Bool, Bool?) -> FSMPool = {
            if let parameter = $1 {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(parameterValue: parameter), newMachine: newMachine))])
            } else {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))])
            }
        }
        let controllableFSM: FSMType = .controllableFSM(AnyControllableFiniteStateMachine(fsm))
        let expectedData: [(Bool, [Bool], Constraint<UInt>)] = [
            (false, [true], .and(lhs: .greaterThan(value: 2000000), rhs: .lessThanEqual(value: 4000000))),
            (false, [true, false], .greaterThan(value: 4000000))
        ]
        let expected: [ConditionalRinglet] = expectedData.map {
            ConditionalRinglet(
                fsm: controllableFSM,
                before: pool(false, nil),
                after: pool($0.0, $0.1.last),
                transitioned: false,
                externalsPreSnapshot: KripkeStatePropertyList(),
                externalsPostSnapshot: KripkeStatePropertyList(),
                preSnapshot: falseProperties,
                postSnapshot: falseProperties,
                calls: $0.1.map {
                    Call(
                        caller: id,
                        callee: id,
                        parameters: ["value": $0],
                        method: .synchronous,
                        fsm: newMachine(["value": $0]).name
                    )
                },
                condition: $0.2
            )
        }
        XCTAssertEqual(ringlets.ringlets.count, expected.count)
        for (result, expected) in zip(ringlets.ringlets, expected) {
            XCTAssertEqual(result.preSnapshot["value"], expected.preSnapshot["value"])
            XCTAssertEqual(result.postSnapshot["value"], expected.postSnapshot["value"])
            XCTAssertEqual(result.calls, expected.calls)
            XCTAssertEqual(result.condition, expected.condition)
        }
    }
    
    func test_computesAllPossibleRingletsForBoundaryStartingTime() throws {
        let fsm = TimeConditionalFiniteStateMachine()
        let id = fsm.gateway.id(of: fsm.name)
        let newMachine: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
            let tempFSM = AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: { _ in fatalError("Should never be called.") })
            let result = tempFSM.parametersFromDictionary($0)
            if result == false {
                fatalError("Unable to call fsm with parameters \($0)")
            }
            return tempFSM
        }
        fsm.gateway.fsms[id] = .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))
        fsm.gateway.stacks[id] = []
        let time: UInt = 2000000
        let ringlets = TimeAwareRinglets(fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)), gateway: fsm.gateway, timer: fsm.timer, startingTime: time)
        let falseProperties = KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: Bool(false))])
        let trueProperties = KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: Bool(true))])
        let pool: (Bool, Bool?) -> FSMPool = {
            if let parameter = $1 {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(parameterValue: parameter), newMachine: newMachine))])
            } else {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))])
            }
        }
        let controllableFSM: FSMType = .controllableFSM(AnyControllableFiniteStateMachine(fsm))
        let expectedData: [(Bool, [Bool], Constraint<UInt>)] = [
            (true, [], .lessThanEqual(value: time)),
            (false, [true], .and(lhs: .greaterThan(value: 2000000), rhs: .lessThanEqual(value: 4000000))),
            (false, [true, false], .greaterThan(value: 4000000))
        ]
        let expected: [ConditionalRinglet] = expectedData.map {
            ConditionalRinglet(
                fsm: controllableFSM,
                before: pool(false, nil),
                after: pool($0.0, $0.1.last),
                transitioned: false,
                externalsPreSnapshot: KripkeStatePropertyList(),
                externalsPostSnapshot: KripkeStatePropertyList(),
                preSnapshot: falseProperties,
                postSnapshot: $0.0 ? trueProperties : falseProperties,
                calls: $0.1.map {
                    Call(
                        caller: id,
                        callee: id,
                        parameters: ["value": $0],
                        method: .synchronous,
                        fsm: newMachine(["value": $0]).name
                    )
                },
                condition: $0.2
            )
        }
        XCTAssertEqual(ringlets.ringlets.count, expected.count)
        for (result, expected) in zip(ringlets.ringlets, expected) {
            XCTAssertEqual(result.preSnapshot["value"], expected.preSnapshot["value"])
            XCTAssertEqual(result.postSnapshot["value"], expected.postSnapshot["value"])
            XCTAssertEqual(result.calls, expected.calls)
            XCTAssertEqual(result.condition, expected.condition)
        }
    }
    
    func test_computesAllPossibleRingletsForMaxStartingTime() throws {
        let fsm = TimeConditionalFiniteStateMachine()
        let id = fsm.gateway.id(of: fsm.name)
        let newMachine: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
            let tempFSM = AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: { _ in fatalError("Should never be called.") })
            let result = tempFSM.parametersFromDictionary($0)
            if result == false {
                fatalError("Unable to call fsm with parameters \($0)")
            }
            return tempFSM
        }
        fsm.gateway.fsms[id] = .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))
        fsm.gateway.stacks[id] = []
        let maxTime: UInt = 4000000
        let ringlets = TimeAwareRinglets(fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)), gateway: fsm.gateway, timer: fsm.timer, startingTime: maxTime + 5000)
        let falseProperties = KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: Bool(false))])
        let pool: (Bool, Bool?) -> FSMPool = {
            if let parameter = $1 {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(parameterValue: parameter), newMachine: newMachine))])
            } else {
                return FSMPool(fsms: [.controllableFSM(AnyControllableFiniteStateMachine(TimeConditionalFiniteStateMachine(value: $0))), .parameterisedFSM(AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: newMachine))])
            }
        }
        let controllableFSM: FSMType = .controllableFSM(AnyControllableFiniteStateMachine(fsm))
        let expectedData: [(Bool, [Bool], Constraint<UInt>)] = [
            (false, [true, false], .greaterThan(value: maxTime))
        ]
        let expected: [ConditionalRinglet] = expectedData.map {
            ConditionalRinglet(
                fsm: controllableFSM,
                before: pool(false, nil),
                after: pool($0.0, $0.1.last),
                transitioned: false,
                externalsPreSnapshot: KripkeStatePropertyList(),
                externalsPostSnapshot: KripkeStatePropertyList(),
                preSnapshot: falseProperties,
                postSnapshot: falseProperties,
                calls: $0.1.map {
                    Call(
                        caller: id,
                        callee: id,
                        parameters: ["value": $0],
                        method: .synchronous,
                        fsm: newMachine(["value": $0]).name
                    )
                },
                condition: $0.2
            )
        }
        XCTAssertEqual(ringlets.ringlets.count, expected.count)
        for (result, expected) in zip(ringlets.ringlets, expected) {
            XCTAssertEqual(result.preSnapshot["value"], expected.preSnapshot["value"])
            XCTAssertEqual(result.postSnapshot["value"], expected.postSnapshot["value"])
            XCTAssertEqual(result.calls, expected.calls)
            XCTAssertEqual(result.condition, expected.condition)
        }
    }
    
    func test_doesNotHaveSideEffectsOnExternalVariables() throws {
        let fsm = AnyControllableFiniteStateMachine(ExternalsFiniteStateMachine())
        let base = { fsm.base as! ExternalsFiniteStateMachine }
        let initialExternalValues = (base().actuators + base().externalVariables + base().sensors).map { $0.val as! Bool }
        _ = TimeAwareRinglets(fsm: .controllableFSM(fsm), gateway: base().gateway, timer: base().timer, startingTime: 0)
        let resultingExternalValues = (base().actuators + base().externalVariables + base().sensors).map { $0.val as! Bool }
        XCTAssertEqual(initialExternalValues, resultingExternalValues)
    }

}

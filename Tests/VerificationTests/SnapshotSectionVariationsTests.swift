/*
 * SnapshotSectionVariationsTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 17/2/21.
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

class SnapshotSectionVariationsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_canGenerateRingletsForOneMachine() throws {
        let fsm = ExternalsFiniteStateMachine()
        let variations = SnapshotSectionVariations(fsms: [CallChain(root: AnyScheduleableFiniteStateMachine(fsm), calls: [])], gateway: fsm.gateway, timer: fsm.timer, startingTime: 0)
        // [actuators, externalVariables, sensors].
        var preExpected = [
            [[false, false, false, false, false, false]],
            [[false, false, false, false, false, true]],
            [[false, false, false, false, true, false]],
            [[false, false, false, true, false, false]],
            [[false, false, true, false, false, false]],
            [[false, false, false, false, true, true]],
            [[false, false, false, true, false, true]],
            [[false, false, true, false, false, true]],
            [[false, false, false, true, true, false]],
            [[false, false, true, false, true, false]],
            [[false, false, true, true, false, false]],
            [[false, false, false, true, true, true]],
            [[false, false, true, false, true, true]],
            [[false, false, true, true, false, true]],
            [[false, false, true, true, true, false]],
            [[false, false, true, true, true, true]],
        ]
        var postExpected = preExpected.map { $0.map { $0.map { !$0 } } }
        XCTAssertEqual(variations.sections.count, preExpected.count)
        check(variations, expected: &preExpected, target: \.externalsPreSnapshot, name: "preSnapshot")
        check(variations, expected: &postExpected, target: \.externalsPostSnapshot, name: "postSnapshot")
        XCTAssertTrue(preExpected.isEmpty)
        XCTAssertTrue(postExpected.isEmpty)
    }
    
    func test_canGenerateRingletsForTwoSameMachines() throws {
        let fsm1 = ExternalsFiniteStateMachine()
        let fsm2 = ExternalsFiniteStateMachine()
        fsm1.name += "1"
        fsm2.name += "2"
        let timer = FSMClock(ringletLengths: [fsm1.name: 10, fsm2.name: 10], scheduleLength: 20)
        fsm1.timer = timer
        fsm2.timer = timer
        fsm2.gateway = fsm1.gateway
        let variations = SnapshotSectionVariations(
            fsms: [
                CallChain(root: AnyScheduleableFiniteStateMachine(fsm1), calls: []),
                CallChain(root: AnyScheduleableFiniteStateMachine(fsm2), calls: [])
            ],
            gateway: fsm1.gateway,
            timer: fsm1.timer,
            startingTime: 0
        )
        // [actuators, externalVariables, sensors].
        let preExpected = [
            [false, false, false, false, false, false],
            [false, false, false, false, false, true],
            [false, false, false, false, true, false],
            [false, false, false, true, false, false],
            [false, false, true, false, false, false],
            [false, false, false, false, true, true],
            [false, false, false, true, false, true],
            [false, false, true, false, false, true],
            [false, false, false, true, true, false],
            [false, false, true, false, true, false],
            [false, false, true, true, false, false],
            [false, false, false, true, true, true],
            [false, false, true, false, true, true],
            [false, false, true, true, false, true],
            [false, false, true, true, true, false],
            [false, false, true, true, true, true],
        ]
        let postExpected = preExpected.map { $0.map { !$0 } }
        XCTAssertEqual(variations.sections.count, preExpected.count)
        
        var preExpectedCopy = Array(zip(preExpected, preExpected).lazy.map { [$0, $1] })
        var postExpectedCopy = Array(zip(postExpected, postExpected).lazy.map { [$0, $1] })
        check(variations, expected: &preExpectedCopy, target: \.externalsPreSnapshot, name: "preSnapshot")
        check(variations, expected: &postExpectedCopy, target: \.externalsPostSnapshot, name: "postSnapshot")
        XCTAssertTrue(preExpectedCopy.isEmpty)
        XCTAssertTrue(postExpectedCopy.isEmpty)
    }
    
    func test_canGenerateRingletsForTwoDifferentMachines() throws {
        let fsm1 = ExternalsFiniteStateMachine()
        let fsm2 = ExternalsFiniteStateMachine2()
        fsm1.name += "1"
        fsm2.name += "2"
        let timer = FSMClock(ringletLengths: [fsm1.name: 10, fsm2.name: 10], scheduleLength: 20)
        fsm1.timer = timer
        fsm2.timer = timer
        fsm2.gateway = fsm1.gateway
        let variations = SnapshotSectionVariations(
            fsms: [
                CallChain(root: AnyScheduleableFiniteStateMachine(fsm1), calls: []),
                CallChain(root: AnyScheduleableFiniteStateMachine(fsm2), calls: [])
            ],
            gateway: fsm1.gateway,
            timer: fsm1.timer,
            startingTime: 0
        )
        // [actuators, externalVariables, sensors].
        var preExpected = [
            [[false, false, false, false, false, false], [false, false, false, false, false, false]],
            [[false, false, false, false, false, false], [false, false, false, false, false, true]],
            [[false, false, false, false, false, false], [false, false, false, false, true, false]],
            [[false, false, false, false, false, false], [false, false, false, true, false, false]],
            [[false, false, false, false, false, false], [false, false, true, false, false, false]],
            [[false, false, false, false, false, false], [false, false, false, false, true, true]],
            [[false, false, false, false, false, false], [false, false, false, true, false, true]],
            [[false, false, false, false, false, false], [false, false, true, false, false, true]],
            [[false, false, false, false, false, false], [false, false, false, true, true, false]],
            [[false, false, false, false, false, false], [false, false, true, false, true, false]],
            [[false, false, false, false, false, false], [false, false, true, true, false, false]],
            [[false, false, false, false, false, false], [false, false, false, true, true, true]],
            [[false, false, false, false, false, false], [false, false, true, false, true, true]],
            [[false, false, false, false, false, false], [false, false, true, true, false, true]],
            [[false, false, false, false, false, false], [false, false, true, true, true, false]],
            [[false, false, false, false, false, false], [false, false, true, true, true, true]],
            
            [[false, false, false, false, false, true], [false, false, false, false, false, false]],
            [[false, false, false, false, false, true], [false, false, false, false, false, true]],
            [[false, false, false, false, false, true], [false, false, false, false, true, false]],
            [[false, false, false, false, false, true], [false, false, false, true, false, false]],
            [[false, false, false, false, false, true], [false, false, true, false, false, false]],
            [[false, false, false, false, false, true], [false, false, false, false, true, true]],
            [[false, false, false, false, false, true], [false, false, false, true, false, true]],
            [[false, false, false, false, false, true], [false, false, true, false, false, true]],
            [[false, false, false, false, false, true], [false, false, false, true, true, false]],
            [[false, false, false, false, false, true], [false, false, true, false, true, false]],
            [[false, false, false, false, false, true], [false, false, true, true, false, false]],
            [[false, false, false, false, false, true], [false, false, false, true, true, true]],
            [[false, false, false, false, false, true], [false, false, true, false, true, true]],
            [[false, false, false, false, false, true], [false, false, true, true, false, true]],
            [[false, false, false, false, false, true], [false, false, true, true, true, false]],
            [[false, false, false, false, false, true], [false, false, true, true, true, true]],
            
            [[false, false, false, false, true, false], [false, false, false, false, false, false]],
            [[false, false, false, false, true, false], [false, false, false, false, false, true]],
            [[false, false, false, false, true, false], [false, false, false, false, true, false]],
            [[false, false, false, false, true, false], [false, false, false, true, false, false]],
            [[false, false, false, false, true, false], [false, false, true, false, false, false]],
            [[false, false, false, false, true, false], [false, false, false, false, true, true]],
            [[false, false, false, false, true, false], [false, false, false, true, false, true]],
            [[false, false, false, false, true, false], [false, false, true, false, false, true]],
            [[false, false, false, false, true, false], [false, false, false, true, true, false]],
            [[false, false, false, false, true, false], [false, false, true, false, true, false]],
            [[false, false, false, false, true, false], [false, false, true, true, false, false]],
            [[false, false, false, false, true, false], [false, false, false, true, true, true]],
            [[false, false, false, false, true, false], [false, false, true, false, true, true]],
            [[false, false, false, false, true, false], [false, false, true, true, false, true]],
            [[false, false, false, false, true, false], [false, false, true, true, true, false]],
            [[false, false, false, false, true, false], [false, false, true, true, true, true]],
            
            [[false, false, false, true, false, false], [false, false, false, false, false, false]],
            [[false, false, false, true, false, false], [false, false, false, false, false, true]],
            [[false, false, false, true, false, false], [false, false, false, false, true, false]],
            [[false, false, false, true, false, false], [false, false, false, true, false, false]],
            [[false, false, false, true, false, false], [false, false, true, false, false, false]],
            [[false, false, false, true, false, false], [false, false, false, false, true, true]],
            [[false, false, false, true, false, false], [false, false, false, true, false, true]],
            [[false, false, false, true, false, false], [false, false, true, false, false, true]],
            [[false, false, false, true, false, false], [false, false, false, true, true, false]],
            [[false, false, false, true, false, false], [false, false, true, false, true, false]],
            [[false, false, false, true, false, false], [false, false, true, true, false, false]],
            [[false, false, false, true, false, false], [false, false, false, true, true, true]],
            [[false, false, false, true, false, false], [false, false, true, false, true, true]],
            [[false, false, false, true, false, false], [false, false, true, true, false, true]],
            [[false, false, false, true, false, false], [false, false, true, true, true, false]],
            [[false, false, false, true, false, false], [false, false, true, true, true, true]],
            
            [[false, false, true, false, false, false], [false, false, false, false, false, false]],
            [[false, false, true, false, false, false], [false, false, false, false, false, true]],
            [[false, false, true, false, false, false], [false, false, false, false, true, false]],
            [[false, false, true, false, false, false], [false, false, false, true, false, false]],
            [[false, false, true, false, false, false], [false, false, true, false, false, false]],
            [[false, false, true, false, false, false], [false, false, false, false, true, true]],
            [[false, false, true, false, false, false], [false, false, false, true, false, true]],
            [[false, false, true, false, false, false], [false, false, true, false, false, true]],
            [[false, false, true, false, false, false], [false, false, false, true, true, false]],
            [[false, false, true, false, false, false], [false, false, true, false, true, false]],
            [[false, false, true, false, false, false], [false, false, true, true, false, false]],
            [[false, false, true, false, false, false], [false, false, false, true, true, true]],
            [[false, false, true, false, false, false], [false, false, true, false, true, true]],
            [[false, false, true, false, false, false], [false, false, true, true, false, true]],
            [[false, false, true, false, false, false], [false, false, true, true, true, false]],
            [[false, false, true, false, false, false], [false, false, true, true, true, true]],
            
            [[false, false, false, false, true, true], [false, false, false, false, false, false]],
            [[false, false, false, false, true, true], [false, false, false, false, false, true]],
            [[false, false, false, false, true, true], [false, false, false, false, true, false]],
            [[false, false, false, false, true, true], [false, false, false, true, false, false]],
            [[false, false, false, false, true, true], [false, false, true, false, false, false]],
            [[false, false, false, false, true, true], [false, false, false, false, true, true]],
            [[false, false, false, false, true, true], [false, false, false, true, false, true]],
            [[false, false, false, false, true, true], [false, false, true, false, false, true]],
            [[false, false, false, false, true, true], [false, false, false, true, true, false]],
            [[false, false, false, false, true, true], [false, false, true, false, true, false]],
            [[false, false, false, false, true, true], [false, false, true, true, false, false]],
            [[false, false, false, false, true, true], [false, false, false, true, true, true]],
            [[false, false, false, false, true, true], [false, false, true, false, true, true]],
            [[false, false, false, false, true, true], [false, false, true, true, false, true]],
            [[false, false, false, false, true, true], [false, false, true, true, true, false]],
            [[false, false, false, false, true, true], [false, false, true, true, true, true]],
            
            [[false, false, false, true, false, true], [false, false, false, false, false, false]],
            [[false, false, false, true, false, true], [false, false, false, false, false, true]],
            [[false, false, false, true, false, true], [false, false, false, false, true, false]],
            [[false, false, false, true, false, true], [false, false, false, true, false, false]],
            [[false, false, false, true, false, true], [false, false, true, false, false, false]],
            [[false, false, false, true, false, true], [false, false, false, false, true, true]],
            [[false, false, false, true, false, true], [false, false, false, true, false, true]],
            [[false, false, false, true, false, true], [false, false, true, false, false, true]],
            [[false, false, false, true, false, true], [false, false, false, true, true, false]],
            [[false, false, false, true, false, true], [false, false, true, false, true, false]],
            [[false, false, false, true, false, true], [false, false, true, true, false, false]],
            [[false, false, false, true, false, true], [false, false, false, true, true, true]],
            [[false, false, false, true, false, true], [false, false, true, false, true, true]],
            [[false, false, false, true, false, true], [false, false, true, true, false, true]],
            [[false, false, false, true, false, true], [false, false, true, true, true, false]],
            [[false, false, false, true, false, true], [false, false, true, true, true, true]],
            
            [[false, false, true, false, false, true], [false, false, false, false, false, false]],
            [[false, false, true, false, false, true], [false, false, false, false, false, true]],
            [[false, false, true, false, false, true], [false, false, false, false, true, false]],
            [[false, false, true, false, false, true], [false, false, false, true, false, false]],
            [[false, false, true, false, false, true], [false, false, true, false, false, false]],
            [[false, false, true, false, false, true], [false, false, false, false, true, true]],
            [[false, false, true, false, false, true], [false, false, false, true, false, true]],
            [[false, false, true, false, false, true], [false, false, true, false, false, true]],
            [[false, false, true, false, false, true], [false, false, false, true, true, false]],
            [[false, false, true, false, false, true], [false, false, true, false, true, false]],
            [[false, false, true, false, false, true], [false, false, true, true, false, false]],
            [[false, false, true, false, false, true], [false, false, false, true, true, true]],
            [[false, false, true, false, false, true], [false, false, true, false, true, true]],
            [[false, false, true, false, false, true], [false, false, true, true, false, true]],
            [[false, false, true, false, false, true], [false, false, true, true, true, false]],
            [[false, false, true, false, false, true], [false, false, true, true, true, true]],
            
            [[false, false, false, true, true, false], [false, false, false, false, false, false]],
            [[false, false, false, true, true, false], [false, false, false, false, false, true]],
            [[false, false, false, true, true, false], [false, false, false, false, true, false]],
            [[false, false, false, true, true, false], [false, false, false, true, false, false]],
            [[false, false, false, true, true, false], [false, false, true, false, false, false]],
            [[false, false, false, true, true, false], [false, false, false, false, true, true]],
            [[false, false, false, true, true, false], [false, false, false, true, false, true]],
            [[false, false, false, true, true, false], [false, false, true, false, false, true]],
            [[false, false, false, true, true, false], [false, false, false, true, true, false]],
            [[false, false, false, true, true, false], [false, false, true, false, true, false]],
            [[false, false, false, true, true, false], [false, false, true, true, false, false]],
            [[false, false, false, true, true, false], [false, false, false, true, true, true]],
            [[false, false, false, true, true, false], [false, false, true, false, true, true]],
            [[false, false, false, true, true, false], [false, false, true, true, false, true]],
            [[false, false, false, true, true, false], [false, false, true, true, true, false]],
            [[false, false, false, true, true, false], [false, false, true, true, true, true]],
            
            [[false, false, true, false, true, false], [false, false, false, false, false, false]],
            [[false, false, true, false, true, false], [false, false, false, false, false, true]],
            [[false, false, true, false, true, false], [false, false, false, false, true, false]],
            [[false, false, true, false, true, false], [false, false, false, true, false, false]],
            [[false, false, true, false, true, false], [false, false, true, false, false, false]],
            [[false, false, true, false, true, false], [false, false, false, false, true, true]],
            [[false, false, true, false, true, false], [false, false, false, true, false, true]],
            [[false, false, true, false, true, false], [false, false, true, false, false, true]],
            [[false, false, true, false, true, false], [false, false, false, true, true, false]],
            [[false, false, true, false, true, false], [false, false, true, false, true, false]],
            [[false, false, true, false, true, false], [false, false, true, true, false, false]],
            [[false, false, true, false, true, false], [false, false, false, true, true, true]],
            [[false, false, true, false, true, false], [false, false, true, false, true, true]],
            [[false, false, true, false, true, false], [false, false, true, true, false, true]],
            [[false, false, true, false, true, false], [false, false, true, true, true, false]],
            [[false, false, true, false, true, false], [false, false, true, true, true, true]],
            
            [[false, false, true, true, false, false], [false, false, false, false, false, false]],
            [[false, false, true, true, false, false], [false, false, false, false, false, true]],
            [[false, false, true, true, false, false], [false, false, false, false, true, false]],
            [[false, false, true, true, false, false], [false, false, false, true, false, false]],
            [[false, false, true, true, false, false], [false, false, true, false, false, false]],
            [[false, false, true, true, false, false], [false, false, false, false, true, true]],
            [[false, false, true, true, false, false], [false, false, false, true, false, true]],
            [[false, false, true, true, false, false], [false, false, true, false, false, true]],
            [[false, false, true, true, false, false], [false, false, false, true, true, false]],
            [[false, false, true, true, false, false], [false, false, true, false, true, false]],
            [[false, false, true, true, false, false], [false, false, true, true, false, false]],
            [[false, false, true, true, false, false], [false, false, false, true, true, true]],
            [[false, false, true, true, false, false], [false, false, true, false, true, true]],
            [[false, false, true, true, false, false], [false, false, true, true, false, true]],
            [[false, false, true, true, false, false], [false, false, true, true, true, false]],
            [[false, false, true, true, false, false], [false, false, true, true, true, true]],
            
            [[false, false, false, true, true, true], [false, false, false, false, false, false]],
            [[false, false, false, true, true, true], [false, false, false, false, false, true]],
            [[false, false, false, true, true, true], [false, false, false, false, true, false]],
            [[false, false, false, true, true, true], [false, false, false, true, false, false]],
            [[false, false, false, true, true, true], [false, false, true, false, false, false]],
            [[false, false, false, true, true, true], [false, false, false, false, true, true]],
            [[false, false, false, true, true, true], [false, false, false, true, false, true]],
            [[false, false, false, true, true, true], [false, false, true, false, false, true]],
            [[false, false, false, true, true, true], [false, false, false, true, true, false]],
            [[false, false, false, true, true, true], [false, false, true, false, true, false]],
            [[false, false, false, true, true, true], [false, false, true, true, false, false]],
            [[false, false, false, true, true, true], [false, false, false, true, true, true]],
            [[false, false, false, true, true, true], [false, false, true, false, true, true]],
            [[false, false, false, true, true, true], [false, false, true, true, false, true]],
            [[false, false, false, true, true, true], [false, false, true, true, true, false]],
            [[false, false, false, true, true, true], [false, false, true, true, true, true]],
            
            [[false, false, true, false, true, true], [false, false, false, false, false, false]],
            [[false, false, true, false, true, true], [false, false, false, false, false, true]],
            [[false, false, true, false, true, true], [false, false, false, false, true, false]],
            [[false, false, true, false, true, true], [false, false, false, true, false, false]],
            [[false, false, true, false, true, true], [false, false, true, false, false, false]],
            [[false, false, true, false, true, true], [false, false, false, false, true, true]],
            [[false, false, true, false, true, true], [false, false, false, true, false, true]],
            [[false, false, true, false, true, true], [false, false, true, false, false, true]],
            [[false, false, true, false, true, true], [false, false, false, true, true, false]],
            [[false, false, true, false, true, true], [false, false, true, false, true, false]],
            [[false, false, true, false, true, true], [false, false, true, true, false, false]],
            [[false, false, true, false, true, true], [false, false, false, true, true, true]],
            [[false, false, true, false, true, true], [false, false, true, false, true, true]],
            [[false, false, true, false, true, true], [false, false, true, true, false, true]],
            [[false, false, true, false, true, true], [false, false, true, true, true, false]],
            [[false, false, true, false, true, true], [false, false, true, true, true, true]],
            
            [[false, false, true, true, false, true], [false, false, false, false, false, false]],
            [[false, false, true, true, false, true], [false, false, false, false, false, true]],
            [[false, false, true, true, false, true], [false, false, false, false, true, false]],
            [[false, false, true, true, false, true], [false, false, false, true, false, false]],
            [[false, false, true, true, false, true], [false, false, true, false, false, false]],
            [[false, false, true, true, false, true], [false, false, false, false, true, true]],
            [[false, false, true, true, false, true], [false, false, false, true, false, true]],
            [[false, false, true, true, false, true], [false, false, true, false, false, true]],
            [[false, false, true, true, false, true], [false, false, false, true, true, false]],
            [[false, false, true, true, false, true], [false, false, true, false, true, false]],
            [[false, false, true, true, false, true], [false, false, true, true, false, false]],
            [[false, false, true, true, false, true], [false, false, false, true, true, true]],
            [[false, false, true, true, false, true], [false, false, true, false, true, true]],
            [[false, false, true, true, false, true], [false, false, true, true, false, true]],
            [[false, false, true, true, false, true], [false, false, true, true, true, false]],
            [[false, false, true, true, false, true], [false, false, true, true, true, true]],
            
            [[false, false, true, true, true, false], [false, false, false, false, false, false]],
            [[false, false, true, true, true, false], [false, false, false, false, false, true]],
            [[false, false, true, true, true, false], [false, false, false, false, true, false]],
            [[false, false, true, true, true, false], [false, false, false, true, false, false]],
            [[false, false, true, true, true, false], [false, false, true, false, false, false]],
            [[false, false, true, true, true, false], [false, false, false, false, true, true]],
            [[false, false, true, true, true, false], [false, false, false, true, false, true]],
            [[false, false, true, true, true, false], [false, false, true, false, false, true]],
            [[false, false, true, true, true, false], [false, false, false, true, true, false]],
            [[false, false, true, true, true, false], [false, false, true, false, true, false]],
            [[false, false, true, true, true, false], [false, false, true, true, false, false]],
            [[false, false, true, true, true, false], [false, false, false, true, true, true]],
            [[false, false, true, true, true, false], [false, false, true, false, true, true]],
            [[false, false, true, true, true, false], [false, false, true, true, false, true]],
            [[false, false, true, true, true, false], [false, false, true, true, true, false]],
            [[false, false, true, true, true, false], [false, false, true, true, true, true]],
            
            [[false, false, true, true, true, true], [false, false, false, false, false, false]],
            [[false, false, true, true, true, true], [false, false, false, false, false, true]],
            [[false, false, true, true, true, true], [false, false, false, false, true, false]],
            [[false, false, true, true, true, true], [false, false, false, true, false, false]],
            [[false, false, true, true, true, true], [false, false, true, false, false, false]],
            [[false, false, true, true, true, true], [false, false, false, false, true, true]],
            [[false, false, true, true, true, true], [false, false, false, true, false, true]],
            [[false, false, true, true, true, true], [false, false, true, false, false, true]],
            [[false, false, true, true, true, true], [false, false, false, true, true, false]],
            [[false, false, true, true, true, true], [false, false, true, false, true, false]],
            [[false, false, true, true, true, true], [false, false, true, true, false, false]],
            [[false, false, true, true, true, true], [false, false, false, true, true, true]],
            [[false, false, true, true, true, true], [false, false, true, false, true, true]],
            [[false, false, true, true, true, true], [false, false, true, true, false, true]],
            [[false, false, true, true, true, true], [false, false, true, true, true, false]],
            [[false, false, true, true, true, true], [false, false, true, true, true, true]]
        ]
        var postExpected = preExpected.map { $0.map { $0.map { !$0 } } }
        XCTAssertEqual(variations.sections.count, 256)
        check(variations, expected: &preExpected, target: \.externalsPreSnapshot, name: "preSnapshot")
        check(variations, expected: &postExpected, target: \.externalsPostSnapshot, name: "postSnapshot")
        XCTAssertTrue(preExpected.isEmpty)
        XCTAssertTrue(postExpected.isEmpty)
    }
    
    private func check(_ variations: SnapshotSectionVariations, expected: inout [[[Bool]]], target: KeyPath<ConditionalRinglet, KripkeStatePropertyList>, name: String) {
        for section in variations.sections {
            let result = section.ringlets.map {
                $0.ringlet[keyPath: target].sorted {
                    $0.key < $1.key
                }.map { $1.value as! Bool }
            }
            print(result)
            guard let index = expected.firstIndex(where: { $0 == result }) else {
                XCTFail("Unexpected \(name) result found: \(result)")
                continue
            }
            expected.remove(at: index)
        }
    }

}

/*
 * RingletTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 14/1/21.
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

class RingletTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_canComputePropertyLists() throws {
        let fsm = ToggleFiniteStateMachine()
        let timeslot = Timeslot(callChain: CallChain(root: fsm.name, calls: []), startingTime: 0, duration: 30, cyclesExecuted: 0)
        let ringlet = Ringlet(
            fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)),
            timeslot: timeslot,
            gateway: fsm.gateway,
            timer: fsm.timer
        )
        XCTAssertEqual(ringlet.preSnapshot["value"], KripkeStateProperty(type: .Bool, value: Bool(false)))
        XCTAssertEqual(ringlet.postSnapshot["value"], KripkeStateProperty(type: .Bool, value: Bool(true)))
        XCTAssertTrue(ringlet.calls.isEmpty)
        XCTAssertTrue(ringlet.afterCalls.isEmpty)
        fsm.next()
        let ringlet2 = Ringlet(
            fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)),
            timeslot: timeslot,
            gateway: fsm.gateway,
            timer: fsm.timer
        )
        XCTAssertEqual(ringlet2.preSnapshot["value"], KripkeStateProperty(type: .Bool, value: Bool(true)))
        XCTAssertEqual(ringlet2.postSnapshot["value"], KripkeStateProperty(type: .Bool, value: Bool(false)))
        XCTAssertTrue(ringlet2.calls.isEmpty)
        XCTAssertTrue(ringlet2.afterCalls.isEmpty)
    }
    
    func test_canDetectCalls() throws {
        let fsm = CallingFiniteStateMachine()
        let timeslot = Timeslot(callChain: CallChain(root: fsm.name, calls: []), startingTime: 0, duration: 30, cyclesExecuted: 0)
        let id = fsm.gateway.id(of: fsm.name)
        let newMachine: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
            let tempFSM = AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: { _ in fatalError("Should never be called.") })
            let result = tempFSM.parametersFromDictionary($0)
            if result == false {
                fatalError("Unable to call fsm with parameters \($0)")
            }
            return tempFSM
        }
        fsm.gateway.fsms[id] = .parameterisedFSM(AnyParameterisedFiniteStateMachine(fsm, newMachine: newMachine))
        fsm.gateway.stacks[id] = []
        let ringlet = Ringlet(
            fsm: .parameterisedFSM(AnyParameterisedFiniteStateMachine(fsm, newMachine: newMachine)),
            timeslot: timeslot,
            gateway: fsm.gateway,
            timer: fsm.timer
        )
        XCTAssertEqual(ringlet.calls.count, 1)
        if ringlet.calls.count != 1 {
            return
        }
        XCTAssertEqual(ringlet.calls[0].caller, id)
        XCTAssertEqual(ringlet.calls[0].callee, id)
        XCTAssertEqual(ringlet.calls[0].parameters.count, 1)
        XCTAssertEqual(ringlet.calls[0].parameters["value"] as? Bool, true)
    }
    
    func test_canDetectAfterCalls() throws {
        let fsm = AfterFiniteStateMachine()
        let timeslot = Timeslot(callChain: CallChain(root: fsm.name, calls: []), startingTime: 0, duration: 30, cyclesExecuted: 0)
        fsm.timer.update(fromFSM: AnyScheduleableFiniteStateMachine(fsm))
        let ringlet = Ringlet(fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)), timeslot: timeslot, gateway: fsm.gateway, timer: fsm.timer)
        XCTAssertEqual(ringlet.afterCalls.count, 1)
        if ringlet.afterCalls.count != 1 {
            return
        }
        XCTAssertTrue(ringlet.afterCalls.contains(4000000))
    }
    
    func test_includesExternalVariables() throws {
        let fsm = ExternalsFiniteStateMachine()
        let timeslot = Timeslot(callChain: CallChain(root: fsm.name, calls: []), startingTime: 0, duration: 30, cyclesExecuted: 0)
        let ringlet = Ringlet(fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)), timeslot: timeslot, gateway: fsm.gateway, timer: fsm.timer)
        print(ringlet.externalsPreSnapshot)
        XCTAssertNotNil(ringlet.externalsPreSnapshot["InMemoryContainer-sensors1"])
        XCTAssertNotNil(ringlet.externalsPreSnapshot["InMemoryContainer-sensors2"])
        XCTAssertNotNil(ringlet.externalsPreSnapshot["InMemoryContainer-externals1"])
        XCTAssertNotNil(ringlet.externalsPreSnapshot["InMemoryContainer-externals2"])
        XCTAssertNotNil(ringlet.externalsPreSnapshot["InMemoryContainer-actuators1"])
        XCTAssertNotNil(ringlet.externalsPreSnapshot["InMemoryContainer-actuators2"])
        XCTAssertEqual(ringlet.externalsPreSnapshot["InMemoryContainer-sensors1"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPreSnapshot["InMemoryContainer-sensors2"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPreSnapshot["InMemoryContainer-externals1"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPreSnapshot["InMemoryContainer-externals2"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPreSnapshot["InMemoryContainer-actuators1"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPreSnapshot["InMemoryContainer-actuators2"]?.value as? Bool, .some(false))
        XCTAssertNotNil(ringlet.externalsPostSnapshot["InMemoryContainer-sensors1"])
        XCTAssertNotNil(ringlet.externalsPostSnapshot["InMemoryContainer-sensors2"])
        XCTAssertNotNil(ringlet.externalsPostSnapshot["InMemoryContainer-externals1"])
        XCTAssertNotNil(ringlet.externalsPostSnapshot["InMemoryContainer-externals2"])
        XCTAssertNotNil(ringlet.externalsPostSnapshot["InMemoryContainer-actuators1"])
        XCTAssertNotNil(ringlet.externalsPostSnapshot["InMemoryContainer-actuators2"])
        XCTAssertEqual(ringlet.externalsPostSnapshot["InMemoryContainer-sensors1"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPostSnapshot["InMemoryContainer-sensors2"]?.value as? Bool, .some(false))
        XCTAssertEqual(ringlet.externalsPostSnapshot["InMemoryContainer-externals1"]?.value as? Bool, .some(true))
        XCTAssertEqual(ringlet.externalsPostSnapshot["InMemoryContainer-externals2"]?.value as? Bool, .some(true))
        XCTAssertEqual(ringlet.externalsPostSnapshot["InMemoryContainer-actuators1"]?.value as? Bool, .some(true))
        XCTAssertEqual(ringlet.externalsPostSnapshot["InMemoryContainer-actuators2"]?.value as? Bool, .some(true))
    }

}

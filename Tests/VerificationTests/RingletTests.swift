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

import FSM
import FSMTest
import KripkeStructure
import LLFSMs
import XCTest

@testable import Verification

final class RingletTests: XCTestCase {

    struct TestMachine: LLFSM {

        struct Environment: EnvironmentSnapshot {

            @ReadWrite
            var externalCount: Int!

        }

        struct Context: ContextProtocol, EmptyInitialisable {

            var count: Int = 0

        }

        struct InitialStateContext: ContextProtocol, EmptyInitialisable {

            var stateCount: Int = 0

        }

        @State(
            name: "Initial",
            initialContext: InitialStateContext(),
            uses: \.$externalCount,
            onEntry: {
                $0.count += 1
                $0.externalCount = $0.externalCount &+ 1
            },
            internal: {
                $0.stateCount += 1
            },
            onExit: {
                $0.stateCount += 1
            },
            transitions: {
                Transition(to: \.$exit, context: InitialStateContext.self) {
                    $0.stateCount >= 2 || $0.after(.seconds(2))
                }
            }
        )
        var initial

        @State(name: "Exit")
        var exit

        var initialState = \Self.$initial

    }

    var externalCount: Int = 0

    var model: TestMachine!

    var info: FSMInformation!

    var fsm: (any Executable)!

    var context: AnySchedulerContext!

    var pool: ExecutablePool!

    var timeslot: Timeslot!

    override func setUp() {
        let mockedHandler = MockedExternalVariable(id: "externalCount", initialValue: 0) {
            self.externalCount
        } saveSnapshot: {
            self.externalCount = $0
        }
        self.model = TestMachine()
        let (executable, contextFactory) = model.initial(
            actuators: [],
            externalVariables: [erase(mockedHandler, mapsTo: \.$externalCount)],
            globalVariables: [],
            sensors: []
        )
        let info = FSMInformation(fsm: model)
        self.fsm = executable
        self.context = contextFactory(nil)
        self.pool = ExecutablePool(executables: [(info, (context, .controllable(executable)))])
        self.timeslot = Timeslot(
            executables: [info.id],
            callChain: CallChain(root: info.id, calls: []),
            startingTime: 0,
            duration: 30,
            cyclesExecuted: 0
        )
        fsm.next(context: context) // Move the fsm past the initial pseudo state.
        externalCount = 0
        fsm.takeSnapshot(context: context) // Set environment variables.
    }

    func test_canComputePropertyLists() throws {
        let clone = context.cloned
        fsm.setup(context: clone)
        let preSnapshot = KripkeStatePropertyList(clone)
        fsm.tearDown(context: clone)
        fsm.next(context: clone)
        fsm.setup(context: clone)
        let postSnapshot = KripkeStatePropertyList(clone)
        fsm.tearDown(context: clone)
        let ringlet = Ringlet(pool: pool, timeslot: timeslot)
        XCTAssertTrue(ringlet.calls.isEmpty)
        XCTAssertEqual(ringlet.afterCalls, [.seconds(2)])
        compare(preSnapshot, ringlet.preSnapshot)
        compare(postSnapshot, ringlet.postSnapshot)
    }

    // func test_canDetectCalls() throws {
    //     let fsm = CallingFiniteStateMachine()
    //     let timeslot = Timeslot(fsms: [fsm.name], callChain: CallChain(root: fsm.name, calls: []), externalDependencies: [], startingTime: 0, duration: 30, cyclesExecuted: 0)
    //     let id = fsm.gateway.id(of: fsm.name)
    //     let newMachine: ([String: Any?]) -> AnyParameterisedFiniteStateMachine = {
    //         let tempFSM = AnyParameterisedFiniteStateMachine(CallingFiniteStateMachine(), newMachine: { _ in fatalError("Should never be called.") })
    //         let result = tempFSM.parametersFromDictionary($0)
    //         if result == false {
    //             fatalError("Unable to call fsm with parameters \($0)")
    //         }
    //         return tempFSM
    //     }
    //     fsm.gateway.fsms[id] = .parameterisedFSM(AnyParameterisedFiniteStateMachine(fsm, newMachine: newMachine))
    //     fsm.gateway.stacks[id] = []
    //     let ringlet = Ringlet(
    //         fsm: .parameterisedFSM(AnyParameterisedFiniteStateMachine(fsm, newMachine: newMachine)),
    //         timeslot: timeslot,
    //         gateway: fsm.gateway,
    //         timer: fsm.timer
    //     )
    //     XCTAssertEqual(ringlet.calls.count, 1)
    //     if ringlet.calls.count != 1 {
    //         return
    //     }
    //     XCTAssertEqual(ringlet.calls[0].caller.id, id)
    //     XCTAssertEqual(ringlet.calls[0].callee.id, id)
    //     XCTAssertEqual(ringlet.calls[0].parameters.count, 1)
    //     XCTAssertEqual(ringlet.calls[0].parameters["value"] as? Bool, true)
    // }

    // func test_canDetectAfterCalls() throws {
    //     let fsm = AfterFiniteStateMachine()
    //     let timeslot = Timeslot(fsms: [fsm.name], callChain: CallChain(root: fsm.name, calls: []), externalDependencies: [], startingTime: 0, duration: 30, cyclesExecuted: 0)
    //     fsm.timer.update(fromFSM: AnyScheduleableFiniteStateMachine(fsm))
    //     let ringlet = Ringlet(fsm: .controllableFSM(AnyControllableFiniteStateMachine(fsm)), timeslot: timeslot, gateway: fsm.gateway, timer: fsm.timer)
    //     XCTAssertEqual(ringlet.afterCalls.count, 1)
    //     if ringlet.afterCalls.count != 1 {
    //         return
    //     }
    //     XCTAssertTrue(ringlet.afterCalls.contains(4000000))
    // }

    func compare(_ lhs: KripkeStateProperty, _ rhs: KripkeStateProperty, key: String? = nil) {
        switch (lhs.type, rhs.type) {
        case (.Compound(let lplist), .Compound(let rplist)):
            compare(lplist, rplist, key: key)
        case (.Optional(let lopt), .Optional(let ropt)):
            XCTAssertEqual(
                lopt == nil,
                ropt == nil,
                "for key \(key ?? "<none>")"
            )
            guard let loptValue = lopt, let roptValue = ropt else {
                return
            }
            compare(loptValue, roptValue)
        case (.Collection(let larr), .Collection(let rarr)):
            XCTAssertEqual(larr.count, rarr.count, "for key \(key ?? "<none>")")
            guard larr.count == rarr.count else { return }
            for (larrValue, rarrValue) in zip(larr, rarr) {
                compare(larrValue, rarrValue)
            }
        default:
            XCTAssertEqual(lhs.type, rhs.type)
            if lhs.type != rhs.type {
                return
            }
            XCTAssertEqual(lhs, rhs, "for key \(key ?? "<none>")")
        }
    }

    func compare(_ lhs: KripkeStatePropertyList, _ rhs: KripkeStatePropertyList, key: String? = nil) {
        if lhs == rhs {
            XCTAssertEqual(lhs, rhs)
            return
        }
        let lsorted = lhs.properties.sorted { $0.key < $1.key }
        let rsorted = rhs.properties.sorted { $0.key < $1.key }
        for ((lkey, lvalue), (rkey, rvalue)) in zip(lsorted, rsorted) {
            XCTAssertEqual(lkey, rkey, "keys of property list do not match")
            if lkey != rkey { continue }
            compare(lvalue, rvalue, key: key.map { $0 + "." + lkey } ?? lkey)
        }
    }

}

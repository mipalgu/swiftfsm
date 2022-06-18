/*
 * SyncDelegateKripkeStructure.swift
 * VerificationTests
 *
 * Created by Callum McColl on 28/12/21.
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

import KripkeStructure
import swiftfsm
import Gateways

struct SyncDelegateKripkeStructure: KripkeStructureProtocol {
    
    var statesLookup: [KripkeStatePropertyList: KripkeState] = [:]
    
    var defaultFSM: DelegateFiniteStateMachine {
        DelegateFiniteStateMachine()
    }
    
    var names: [String] = (0..<2).map { DelegateFiniteStateMachine().name + "\($0)" }
    
    typealias FSM = DelegateFiniteStateMachine
    
    typealias Data = (Bool, Bool??)

    func propertyList(executing: String, readState: Bool, fsms: [(value: (Bool, Bool??), currentState: String, previousState: String)]) -> KripkeStatePropertyList {
        KripkeStatePropertyList()
    }
    
    func fsm(named name: String, data: (Bool, Bool??)) -> DelegateFiniteStateMachine {
        let fsm = DelegateFiniteStateMachine()
        fsm.syncCall = data.0
        fsm.name = name
        let id = fsm.gateway.id(of: fsm.calleeName)
        let callee = AnyParameterisedFiniteStateMachine(CalleeFiniteStateMachine()) { _ in fatalError("Creating Machine") }
        fsm.gateway.fsms[id] = .parameterisedFSM(callee)
        if let result = data.1 {
            let promiseData = PromiseData(fsm: callee, hasFinished: result != nil)
            promiseData.result = result
            fsm.gateway.stacks[id] = [promiseData]
            (fsm.initialState as! DelegateFiniteStateMachine.InitialState).promise = Promise(
                hasFinished: { result != nil },
                result: { result! }
            )
        }
        return fsm
    }
    
    func emptyState(named name: String) -> MiPalState {
        EmptyMiPalState(name)
    }
    
    mutating func kripkeState(readState: Bool, value: (syncCall: Bool, result: Bool??), currentState: String, previousState: String, targets: [(String, Bool, KripkeStatePropertyList, UInt, Constraint<UInt>?)]) -> KripkeState {
        kripkeState(
            executing: names[0],
            readState: readState,
            fsms: [(value, currentState, previousState)],
            targets: targets
        )
    }
    
    mutating func kripkeState(
        executing: String,
        readState: Bool,
        fsm1: (value: (Bool, Bool??), currentState: String, previousState: String),
        fsm2: (value: (Bool, Bool??), currentState: String, previousState: String),
        targets: [(String, Bool, KripkeStatePropertyList, UInt, Constraint<UInt>?)]
    ) -> KripkeState {
        kripkeState(
            executing: executing,
            readState: readState,
            fsms: [fsm1, fsm2].map { ($0, $1, $2) },
            targets: targets
        )
    }
    
    mutating func target(
        executing: String,
        readState: Bool,
        resetClock: Bool,
        duration: UInt,
        fsm1: (value: (Bool, Bool??), currentState: String, previousState: String),
        fsm2: (value: (Bool, Bool??), currentState: String, previousState: String)
    ) -> (String, Bool, KripkeStatePropertyList, UInt, Constraint<UInt>?) {
        self.target(
            executing: executing,
            readState: readState,
            resetClock: resetClock,
            duration: duration,
            fsms: [fsm1, fsm2].map { ($0, $1, $2) },
            constraint: nil
        )
    }
    
    func target(readState: Bool, resetClock: Bool, duration: UInt, data: (syncCall: Bool, result: Bool??), currentState: String, previousState: String, constraint: Constraint<UInt>? = nil) -> (String, Bool, KripkeStatePropertyList, UInt, Constraint<UInt>?) {
        self.target(
            executing: names[0],
            readState: readState,
            resetClock: resetClock,
            duration: duration,
            fsms: [(data, currentState, previousState)],
            constraint: constraint
        )
    }
    
    mutating func single(name fsmName: String, startingTime: UInt, duration: UInt, cycleLength: UInt) -> Set<KripkeState> {
        statesLookup.removeAll(keepingCapacity: true)
        names = [fsmName]
        let gap = cycleLength - duration - startingTime
        let syncCall = false
        let fsm = SensorFiniteStateMachine()
        fsm.name = fsmName
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        return [
            kripkeState(
                readState: true,
                value: (syncCall: syncCall, result: nil),
                currentState: initial,
                previousState: previous,
                targets: [
                    target(
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        data: (syncCall: syncCall, result: .some(nil)),
                        currentState: initial,
                        previousState: initial
                    )
                ]
            ),
            kripkeState(
                readState: false,
                value: (syncCall: syncCall, result: nil),
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        readState: true,
                        resetClock: false,
                        duration: gap,
                        data: (syncCall: syncCall, result: .some(nil)),
                        currentState: initial,
                        previousState: initial,
                        constraint: .lessThan(value: cycleLength * 2)
                    ),
                    target(
                        readState: true,
                        resetClock: false,
                        duration: gap,
                        data: (syncCall: syncCall, result: .some(false)),
                        currentState: initial,
                        previousState: initial,
                        constraint: .greaterThanEqual(value: cycleLength * 2)
                    )
                ]
            ),
            kripkeState(
                readState: true,
                value: (syncCall: syncCall, result: .some(nil)),
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        data: (syncCall: syncCall, result: .some(nil)),
                        currentState: initial,
                        previousState: initial
                    )
                ]
            ),
            kripkeState(
                readState: true,
                value: (syncCall: syncCall, result: .some(false)),
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        data: (syncCall: syncCall, result: .some(false)),
                        currentState: exit,
                        previousState: initial
                    )
                ]
            ),
            kripkeState(
                readState: false,
                value: (syncCall: syncCall, result: .some(false)),
                currentState: exit,
                previousState: initial,
                targets: [
                    target(
                        readState: true,
                        resetClock: true,
                        duration: gap,
                        data: (syncCall: syncCall, result: .some(false)),
                        currentState: exit,
                        previousState: initial
                    )
                ]
            ),
            kripkeState(
                readState: true,
                value: (syncCall: syncCall, result: .some(false)),
                currentState: exit,
                previousState: initial,
                targets: [
                    target(
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        data: (syncCall: syncCall, result: .some(false)),
                        currentState: exit,
                        previousState: exit
                    )
                ]
            ),
            kripkeState(
                readState: false,
                value: (syncCall: syncCall, result: .some(false)),
                currentState: exit,
                previousState: exit,
                targets: []
            )
        ]
    }
    
    mutating func two(fsm1: (name: String, startingTime: UInt, duration: UInt), fsm2: (name: String, startingTime: UInt, duration: UInt), cycleLength: UInt) -> Set<KripkeState> {
        statesLookup.removeAll(keepingCapacity: true)
        names = [fsm1.name, fsm2.name]
        let fsm1Name = fsm1.name
        let fsm2Name = fsm2.name
        let fsm = SensorFiniteStateMachine()
        fsm.name = fsm1Name
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        let fsm1Gap = fsm2.startingTime - fsm1.duration - fsm1.startingTime
        let fsm2Gap = fsm1.startingTime
        return [
            
        ]
    }
    
    
}

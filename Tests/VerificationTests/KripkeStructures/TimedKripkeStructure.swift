/*
 * TimedKripkeStructure.swift
 * VerificationTests
 *
 * Created by Callum McColl on 27/12/21.
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

struct TimedKripkeStructure: KripkeStructureProtocol {
    
    var statesLookup: [KripkeStatePropertyList: KripkeState] = [:]
    
    var defaultFSM: SimpleTimeConditionalFiniteStateMachine {
        SimpleTimeConditionalFiniteStateMachine()
    }
    
    var names: [String] = (0..<2).map { SimpleTimeConditionalFiniteStateMachine().name + "\($0)" }
    
    func fsm(named name: String, data: Int) -> SimpleTimeConditionalFiniteStateMachine {
        let fsm = SimpleTimeConditionalFiniteStateMachine()
        fsm.name = name
        fsm.value = data
        return fsm
    }
    
    func emptyState(named name: String) -> MiPalState {
        EmptyMiPalState(name)
    }

    func propertyList(executing: String, readState: Bool, fsms: [(value: Int, currentState: String, previousState: String)]) -> KripkeStatePropertyList {
        let configurations: [(String, Data, String, String)] = fsms.enumerated().map {
            (names[$0], $1.0, $1.1, $1.2)
        }
        let resetClocks = resetClocksProperty(executing: executing, readState: readState, fsms: fsms)
        var currentState: String!
        var previousState: String!
        let fsmProperties = configurations.map { (data) -> ((String, KripkeStateProperty), (String, FSM)) in
            let fsm = fsm(named: data.0, data: data.1)
            if data.0 == executing {
                currentState = data.2
                previousState = data.3
            }
            if data.2 == fsm.initialState.name {
                fsm.currentState = fsm.initialState
            } else {
                fsm.currentState = emptyState(named: data.2)
            }
            if data.3 == fsm.initialState.name {
                fsm.previousState = fsm.initialState
            } else {
                fsm.previousState = emptyState(named: data.3)
            }
            fsm.ringlet.previousState = fsm.previousState
            fsm.ringlet.shouldExecuteOnEntry = fsm.previousState != fsm.currentState
            let ringlet = KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(["shouldExecuteOnEntry": .init(type: .Bool, value: fsm.ringlet.shouldExecuteOnEntry)])),
                value: ["shouldExecuteOnEntry": fsm.ringlet.shouldExecuteOnEntry]
            )
            let props = KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList([
                    "currentState": .init(type: .String, value: fsm.currentState.name),
                    "hasFinished": .init(type: .Bool, value: fsm.hasFinished),
                    "isSuspended": .init(type: .Bool, value: fsm.isSuspended),
                    "ringlet": ringlet,
                    "value": .init(type: .Int, value: fsm.value)
                ])),
                value: fsm
            )
            return ((fsm.name, props), (fsm.name, fsm))
        }
        return KripkeStatePropertyList([
            "fsms": .init(
                type: .Compound(KripkeStatePropertyList(Dictionary(uniqueKeysWithValues: fsmProperties.map(\.0)))),
                value: Dictionary(uniqueKeysWithValues: fsmProperties.map(\.1))
            ),
            "pc": KripkeStateProperty(
                type: .String,
                value: executing + "." + (readState ? currentState! : previousState!) + "." + (readState ? "R" : "W")
            ),
            "resetClocks": resetClocks
        ])
    }
    
    mutating func kripkeState(executing: String, readState: Bool, value: Int, currentState: String, previousState: String, targets: [Target]) -> KripkeState {
        kripkeState(
            executing: executing,
            readState: readState,
            fsms: [(value, currentState, previousState)],
            targets: targets
        )
    }
    
    mutating func kripkeState(
        executing: String,
        readState: Bool,
        fsm1: (value: Int, currentState: String, previousState: String),
        fsm2: (value: Int, currentState: String, previousState: String),
        targets: [Target]
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
        clock: String? = nil,
        duration: UInt,
        fsm1: (value: Int, currentState: String, previousState: String),
        fsm2: (value: Int, currentState: String, previousState: String),
        constraint: Constraint<UInt>? = nil
    ) -> Target {
        self.target(
            executing: executing,
            readState: readState,
            resetClock: resetClock,
            clock: clock,
            duration: duration,
            fsms: [fsm1, fsm2].map { ($0, $1, $2) },
            constraint: constraint
        )
    }
    
    func target(executing: String, readState: Bool, resetClock: Bool, clock: String? = nil, duration: UInt, value: Int, currentState: String, previousState: String, constraint: Constraint<UInt>? = nil) -> Target {
        self.target(
            executing: executing,
            readState: readState,
            resetClock: resetClock,
            clock: clock,
            duration: duration,
            fsms: [(value, currentState, previousState)],
            constraint: constraint
        )
    }
    
    mutating func single(name fsmName: String, startingTime: UInt, duration: UInt, cycleLength: UInt) -> Set<KripkeState> {
        statesLookup.removeAll(keepingCapacity: true)
        names = [fsmName]
        let fsm = SimpleTimeConditionalFiniteStateMachine()
        fsm.name = fsmName
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        return [
            kripkeState(
                executing: fsmName,
                readState: true,
                value: 0,
                currentState: initial,
                previousState: previous,
                targets: [
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 0,
                        currentState: initial,
                        previousState: initial,
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 5,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: exit,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 25,
                        currentState: exit,
                        previousState: initial,
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 0,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: true,
                        resetClock: false,
                        duration: cycleLength - duration,
                        value: 0,
                        currentState: initial,
                        previousState: initial,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: true,
                value: 0,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 0,
                        currentState: initial,
                        previousState: initial,
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 5,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: exit,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 25,
                        currentState: exit,
                        previousState: initial,
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 5,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: true,
                        resetClock: false,
                        duration: cycleLength - duration,
                        value: 5,
                        currentState: initial,
                        previousState: initial,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: true,
                value: 5,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 0,
                        currentState: initial,
                        previousState: initial,
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 5,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: exit,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 25,
                        currentState: exit,
                        previousState: initial,
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 15,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: true,
                        resetClock: false,
                        duration: cycleLength - duration,
                        value: 15,
                        currentState: initial,
                        previousState: initial,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: true,
                value: 15,
                currentState: initial,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 0,
                        currentState: initial,
                        previousState: initial,
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 5,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: initial,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: exit,
                        previousState: initial,
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 25,
                        currentState: exit,
                        previousState: initial,
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 15,
                currentState: exit,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: true,
                        resetClock: true,
                        duration: cycleLength - duration,
                        value: 15,
                        currentState: exit,
                        previousState: initial,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: true,
                value: 15,
                currentState: exit,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 15,
                        currentState: exit,
                        previousState: exit,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 15,
                currentState: exit,
                previousState: exit,
                targets: []
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 25,
                currentState: exit,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: true,
                        resetClock: true,
                        duration: cycleLength - duration,
                        value: 25,
                        currentState: exit,
                        previousState: initial,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: true,
                value: 25,
                currentState: exit,
                previousState: initial,
                targets: [
                    target(
                        executing: fsmName,
                        readState: false,
                        resetClock: false,
                        duration: duration,
                        value: 25,
                        currentState: exit,
                        previousState: exit,
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsmName,
                readState: false,
                value: 25,
                currentState: exit,
                previousState: exit,
                targets: []
            ),
        ]
    }
    
    mutating func two(fsm1: (name: String, startingTime: UInt, duration: UInt), fsm2: (name: String, startingTime: UInt, duration: UInt), cycleLength: UInt) -> Set<KripkeState> {
        names = [fsm1.name, fsm2.name]
        let fsm1Name = fsm1.name
        let fsm2Name = fsm2.name
        let fsm = SimpleTimeConditionalFiniteStateMachine()
        fsm.name = fsm1.name
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        let fsm1Gap = fsm2.startingTime - fsm1.duration - fsm1.startingTime
        let fsm2Gap = fsm1.startingTime
        return [
            // MARK: - (R(fsm1), (0, initial, previous), (0, initial, previous))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (0, initial, previous))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (0, initial, previous))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (0, initial, previous))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (0, initial, previous))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (0, initial, previous))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (0, initial, initial), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (0, initial, initial), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (0, initial, initial), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (0, initial, initial), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (0, initial, initial), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (5, initial, initial), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (5, initial, initial), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (5, initial, initial), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (5, initial, initial), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (5, initial, initial), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (15, initial, initial), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, initial, initial), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, initial, initial), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, initial, initial), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, initial, initial), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (15, exit, initial), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, initial), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, initial), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, initial), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, initial), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm1), (25, exit, initial), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, initial), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, initial), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, initial), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, initial), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    ),
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    ),
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm1), (15, exit, exit), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, exit), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, exit), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, exit), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, exit), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm1), (25, exit, exit), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, exit), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, exit), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, exit), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, exit), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    ),
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm2), (0, initial, initial), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    ),
                ]
            ),
            // MARK: (R(fsm2), (5, initial, initial), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, initial, initial), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (15, exit, initial), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, initial), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm1), (0, initial, initial), (15, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (0, initial, initial), (25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (5, initial, initial), (15, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (5, initial, initial), (25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (15, initial, initial), (15, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, initial, initial), (25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm1), (15, exit, initial), (15, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (15, exit, initial), (25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm1), (25, exit, initial), (15, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm1), (25, exit, initial), (25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm1.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm2), (15, exit, exit), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, exit), (0, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (15, exit, exit), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, exit), (5, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (15, exit, exit), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, exit), (15, initial, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .lessThanEqual(value: 5000)
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 5000), rhs: .lessThanEqual(value: 15000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 15000), rhs: .lessThanEqual(value: 20000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .and(lhs: .greaterThan(value: 20000), rhs: .lessThanEqual(value: 25000))
                    ),
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: .greaterThan(value: 25000)
                    )
                ]
            ),
            // MARK: - (R(fsm2), (15, exit, exit), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, exit), (15, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (R(fsm2), (15, exit, exit), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (R(fsm2), (25, exit, exit), (25, exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: true,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: false,
                        resetClock: false,
                        duration: fsm2.duration,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm1) (*, initial|exit, initial), (0, initial, previous))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: previous
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: previous
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm2), (0, initial, initial), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm2), (5, initial, initial), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm2), (15, initial, initial), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm2), (15, exit, initial), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm2), (25, exit, initial), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm1), (*, initial|exit, initial), (0, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm1), (*, initial|exit, initial), (5, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm1), (*, initial|exit, initial), (15, initial, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm1), (*, initial|exit, initial), (15, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm1), (*, initial|exit, initial), (25, exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm1), (15, exit, exit), (*, initial|exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm1), (25, exit, exit), (*, initial|exit, initial))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm1), (*, initial|exit, initial), (15, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm1), (*, initial|exit, initial), (25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm2Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm1Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm2), (*, initial|exit, initial), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm2), (*, initial|exit, initial), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: true,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm2), (15, exit, exit), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 15,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: (W(fsm2), (25, exit, exit), (*, initial|exit, initial))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 0,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 0,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 5,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 5,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: initial,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: initial,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 15,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: initial
                ),
                targets: [
                    target(
                        executing: fsm1Name,
                        readState: true,
                        resetClock: false,
                        duration: fsm2Gap,
                        fsm1: (
                            value: 25,
                            currentState: exit,
                            previousState: exit
                        ),
                        fsm2: (
                            value: 25,
                            currentState: exit,
                            previousState: initial
                        ),
                        constraint: nil
                    )
                ]
            ),
            // MARK: - (W(fsm2), (15|25, exit, exit), (15, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            // MARK: (W(fsm2), (15|25, exit, exit), (25, exit, exit))
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            kripkeState(
                executing: fsm2Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            // MARK: - (W(fsm1), (15, exit, exit), (15|25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            // MARK: (W(fsm1), (25, exit, exit), (15|25, exit, exit))
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 15,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
            kripkeState(
                executing: fsm1Name,
                readState: false,
                fsm1: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                fsm2: (
                    value: 25,
                    currentState: exit,
                    previousState: exit
                ),
                targets: []
            ),
        ]
    }
    
    
}

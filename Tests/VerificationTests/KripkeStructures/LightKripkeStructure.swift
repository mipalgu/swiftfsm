/*
 * LightKripkeStructure.swift
 * KripkeStructures
 *
 * Created by Callum McColl on 4/7/2022.
 * Copyright © 2022 Callum McColl. All rights reserved.
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

struct LightKripkeStructure: KripkeStructureProtocol {

    var statesLookup: [KripkeStatePropertyList: KripkeState] = [:]

    var defaultFSM: LightFiniteStateMachine {
        LightFiniteStateMachine()
    }

    var names: [String] = (0..<2).map { LightFiniteStateMachine().name + "\($0)" }

    typealias FSM = LightFiniteStateMachine

    typealias Data = (status: MicrowaveStatus, light: Bool)

    func propertyList(executing: String, readState: Bool, fsms: [(value: (status: MicrowaveStatus, light: Bool), currentState: String, previousState: String)]) -> KripkeStatePropertyList {
        let configurations: [(String, Data, String, String)] = fsms.enumerated().map {
            (names[$0], $1.0, $1.1, $1.2)
        }
        var currentState: String!
        var previousState: String!
        let resetClocks = resetClocksProperty(executing: executing, readState: readState, fsms: fsms)
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
            let externalVariables = KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList([
                    fsm.status.name: .init(type: .Compound(KripkeStatePropertyList(properties: [
                        "buttonPushed": KripkeStateProperty(type: .Bool, value: fsm.status.val.buttonPushed),
                        "doorOpen": KripkeStateProperty(type: .Bool, value: fsm.status.val.doorOpen),
                        "timeLeft": KripkeStateProperty(type: .Bool, value: fsm.status.val.timeLeft)
                    ])), value: fsm.status.val),
                    fsm.light.name: .init(type: .Bool, value: fsm.light.val)
                ])),
                value: [fsm.status.name: fsm.status.val, fsm.light.name: fsm.light.val]
            )
            let ringlet = KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(["shouldExecuteOnEntry": .init(type: .Bool, value: fsm.ringlet.shouldExecuteOnEntry)])),
                value: fsm.ringlet
            )
            let props = KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList([
                    "currentState": .init(type: .String, value: fsm.currentState.name),
                    "hasFinished": .init(type: .Bool, value: fsm.hasFinished),
                    "isSuspended": .init(type: .Bool, value: fsm.isSuspended),
                    "ringlet": ringlet,
                    "externalVariables": externalVariables
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

    func fsm(named name: String, data: (status: MicrowaveStatus, light: Bool)) -> LightFiniteStateMachine {
        let fsm = LightFiniteStateMachine()
        fsm.name = name
        fsm.status.val = data.status
        fsm.light.val = data.light
        return fsm
    }

    func emptyState(named name: String) -> MiPalState {
        EmptyMiPalState(name)
    }

    mutating func kripkeState(readState: Bool, status: MicrowaveStatus, light: Bool, currentState: String, previousState: String, targets: [Target]) -> KripkeState {
        kripkeState(
            executing: names[0],
            readState: readState,
            fsms: [((status, light), currentState, previousState)],
            targets: targets
        )
    }

    mutating func kripkeState(
        executing: String,
        readState: Bool,
        fsm1: (status: MicrowaveStatus, light: Bool, currentState: String, previousState: String),
        fsm2: (status: MicrowaveStatus, light: Bool, currentState: String, previousState: String),
        targets: [Target]
    ) -> KripkeState {
        kripkeState(
            executing: executing,
            readState: readState,
            fsms: [fsm1, fsm2].map { (($0, $1), $2, $3) },
            targets: targets
        )
    }

    mutating func target(
        executing: String,
        readState: Bool,
        resetClock: Bool,
        clock: String? = nil,
        duration: UInt,
        fsm1: (status: MicrowaveStatus, light: Bool, currentState: String, previousState: String),
        fsm2: (status: MicrowaveStatus, light: Bool, currentState: String, previousState: String)
    ) -> Target {
        self.target(
            executing: executing,
            readState: readState,
            resetClock: resetClock,
            clock: clock,
            duration: duration,
            fsms: [fsm1, fsm2].map { ((status: $0, light: $1), $2, $3) },
            constraint: nil
        )
    }

    func target(readState: Bool, resetClock: Bool, clock: String? = nil, duration: UInt, status: MicrowaveStatus, light: Bool, currentState: String, previousState: String) -> Target {
        self.target(
            executing: names[0],
            readState: readState,
            resetClock: resetClock,
            clock: clock,
            duration: duration,
            fsms: [((status, light), currentState, previousState)],
            constraint: nil
        )
    }

    mutating func single(name fsmName: String, startingTime: UInt, duration: UInt, cycleLength: UInt) -> Set<KripkeState> {
        statesLookup.removeAll(keepingCapacity: true)
        names = [fsmName]
        let fsm = LightFiniteStateMachine()
        fsm.name = fsmName
        let off = fsm.initialState.name
        let on = fsm.onState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        return [
            kripkeState(
                readState: true,
                status: .init(buttonPushed: false, doorOpen: false, timeLeft: false),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: false, doorOpen: false, timeLeft: false), light: false, currentState: off, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: false, timeLeft: false),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: false, timeLeft: false), light: false, currentState: off, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: false, doorOpen: true, timeLeft: false),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: false, doorOpen: true, timeLeft: false), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: false, doorOpen: false, timeLeft: true),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: false, doorOpen: false, timeLeft: true), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: false, doorOpen: false, timeLeft: false),
                light: true,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: false, doorOpen: false, timeLeft: false), light: false, currentState: off, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: true, timeLeft: false),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: true, timeLeft: false), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: false, timeLeft: true),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: false, timeLeft: true), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: false, timeLeft: false),
                light: true,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: false, timeLeft: false), light: false, currentState: off, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: false, doorOpen: true, timeLeft: true),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: false, doorOpen: true, timeLeft: true), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: false, doorOpen: true, timeLeft: false),
                light: true,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: false, doorOpen: true, timeLeft: false), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: true, timeLeft: true),
                light: false,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: true, timeLeft: true), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: true, timeLeft: false),
                light: true,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: true, timeLeft: false), light: false, currentState: on, previousState: off)
                ]
            ),
            kripkeState(
                readState: true,
                status: .init(buttonPushed: true, doorOpen: true, timeLeft: true),
                light: true,
                currentState: off,
                previousState: previous,
                targets: [
                    target(readState: false, resetClock: false, duration: duration, status: .init(buttonPushed: true, doorOpen: true, timeLeft: false), light: false, currentState: on, previousState: off)
                ]
            ),
        ]
    }

    mutating func two(fsm1: (name: String, startingTime: UInt, duration: UInt), fsm2: (name: String, startingTime: UInt, duration: UInt), cycleLength: UInt) -> Set<KripkeState> {
        statesLookup.removeAll(keepingCapacity: true)
        names = [fsm1.name, fsm2.name]
        let fsm1Name = fsm1.name
        let fsm2Name = fsm2.name
        let fsm = LightFiniteStateMachine()
        fsm.name = fsm1Name
        let initial = fsm.initialState.name
        let previous = fsm.initialPreviousState.name
        let exit = fsm.exitState.name
        let fsm1Gap = fsm2.startingTime - fsm1.duration - fsm1.startingTime
        let fsm2Gap = fsm1.startingTime
        return []
    }


}

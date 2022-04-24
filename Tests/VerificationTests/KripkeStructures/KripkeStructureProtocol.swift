/*
 * KripkeStructureProtocol.swift
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

@testable import KripkeStructure
import swiftfsm

protocol KripkeStructureProtocol {
    
    associatedtype FSM: ConvertibleToScheduleableFiniteStateMachine, StateExecuterDelegator, OptimizedStateExecuter where FSM._StateType == MiPalState, FSM.RingletType == MiPalRinglet
    associatedtype Data
    
    var statesLookup: [KripkeStatePropertyList: KripkeState] { get set }
    
    var defaultFSM: FSM { get }
    
    var names: [String] { get }
    
    func fsm(named: String, data: Data) -> FSM
    
    func emptyState(named: String) -> FSM._StateType
    
    mutating func single(name: String, startingTime: UInt, duration: UInt, cycleLength: UInt) -> Set<KripkeState>
    
    mutating func two(
        fsm1: (name: String, startingTime: UInt, duration: UInt),
        fsm2: (name: String, startingTime: UInt, duration: UInt),
        cycleLength: UInt
    ) -> Set<KripkeState>
    
}

extension KripkeStructureProtocol {
    
    func propertyList(
        executing: String,
        readState: Bool,
        fsms: [(value: Data, currentState: String, previousState: String)]
    ) -> KripkeStatePropertyList {
        let configurations: [(String, Data, String, String)] = fsms.enumerated().map {
            (names[$0], $1.0, $1.1, $1.2)
        }
        var currentState: String!
        var previousState: String!
        let fsms = configurations.map { (data) -> (String, KripkeStatePropertyList, FSM) in
            var fsm = fsm(named: data.0, data: data.1)
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
            let fsmProperties = KripkeStatePropertyList(fsm)
            return (fsm.name, fsmProperties, fsm)
        }
        return [
            "fsms": KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(Dictionary<String, KripkeStateProperty>(uniqueKeysWithValues: fsms.map {
                    ($0, KripkeStateProperty(type: .Compound($1), value: $2))
                }))),
                value: Dictionary<String, FSM>(uniqueKeysWithValues: fsms.map { ($0.0, $0.2) })
            ),
            "pc": KripkeStateProperty(type: .String, value: executing + "." + (readState ? currentState! : previousState!) + "." + (readState ? "R" : "W"))
        ]
    }
    
    func target(
        executing: String,
        readState: Bool,
        resetClock: Bool,
        duration: UInt,
        fsms: [(value: Data, currentState: String, previousState: String)],
        constraint: Constraint<UInt>? = nil
    ) -> (String, Bool, KripkeStatePropertyList, UInt, Constraint<UInt>?) {
        return (
            executing,
            resetClock,
            propertyList(executing: executing, readState: readState, fsms: fsms),
            duration,
            constraint
        )
    }
    
    mutating func kripkeState(
        executing: String,
        readState: Bool,
        fsms: [(value: Data, currentState: String, previousState: String)],
        targets: [(executing: String, resetClock: Bool, target: KripkeStatePropertyList, duration: UInt, constraint: Constraint<UInt>?)]
    ) -> KripkeState {
        let fsm = defaultFSM
        let properties = propertyList(executing: executing, readState: readState, fsms: fsms)
        let edges = targets.map {
            KripkeEdge(
                clockName: $0,
                constraint: $4,
                resetClock: $1,
                takeSnapshot: !readState,
                time: $3,
                target: $2
            )
        }
        let state = statesLookup[properties] ?? KripkeState(isInitial: executing == names[0] && fsms[0].previousState == fsm.initialPreviousState.name, properties: properties)
        if nil == statesLookup[properties] {
            statesLookup[properties] = state
        }
        state.edges = Set(edges)
        return state
    }
    
}

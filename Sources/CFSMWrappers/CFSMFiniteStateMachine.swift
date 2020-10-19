/*
 * CFSMFiniteStateMachine.swift
 * CFSMWrappers
 *
 * Created by Callum McColl on 20/10/20.
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

import swiftfsm

internal final class CFSMFiniteStateMachine: MachineProtocol {

    public typealias _StateType = MiPalState

    fileprivate var allStates: [String: MiPalState] {
        var stateCache: [String: MiPalState] = [:]
        func fetchAllStates(fromState state: MiPalState) {
            if stateCache[state.name] != nil {
                return
            }
            stateCache[state.name] = state
            state.transitions.forEach {
                fetchAllStates(fromState: $0.target)
            }
        }
        fetchAllStates(fromState: self.initialState)
        fetchAllStates(fromState: self.suspendState)
        fetchAllStates(fromState: self.exitState)
        return stateCache
    }

    public var computedVars: [String: Any] {
        return [
            "currentState": self.currentState.name,
            "fsmVars": self.fsmVars.vars,
            "states": self.allStates,
        ]
    }

    /**
     * All external variables used by the machine.
     */
    public var externalVariables: [AnySnapshotController] = []

    public var sensors: [AnySnapshotController] = []

    public var actuators: [AnySnapshotController] = []

    public var snapshotSensors: [AnySnapshotController] = []

    public var snapshotActuators: [AnySnapshotController] = []

    public var validVars: [String: [Any]] {
        return [
            "currentState": [],
            "exitState": [],
            "externalVariables": [],
            "sensors": [],
            "actuators": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "fsmVars": [],
            "initialPreviousState": [],
            "initialState": [],
            "name": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "external_buttonPushed": [],
            "external_doorOpen": [],
            "external_timeLeft": [],
        ]
    }

    /**
     *  The state that is currently executing.
     */
    public var currentState: MiPalState

    /**
     *  The state that is used to exit the FSM.
     */
    public private(set) var exitState: MiPalState

    /**
     * All FSM variables used by the machine.
     */
    public let fsmVars: SimpleVariablesContainer<EmptyVariables> = SimpleVariablesContainer(vars: EmptyVariables())

    /**
     *  The initial state of the previous state.
     *
     *  `previousState` is set to this value on restart.
     */
    public private(set) var initialPreviousState: MiPalState

    /**
     *  The starting state of the FSM.
     */
    public private(set) var initialState: MiPalState

    /**
     *  The name of the FSM.
     *
     *  - Warning: This must be unique between FSMs.
     */
    public let name: String

    /**
     *  The last state that was executed.
     */
    public var previousState: MiPalState

    /**
     *  An instance of `Ringlet` that is used to execute the states.
     */
    public fileprivate(set) var ringlet: MiPalRinglet

    /**
     * All submachines of this machine.
     */
    public var submachines: [AnyControllableFiniteStateMachine] = []

    /**
     *  The state that was the `currentState` before the FSM was suspended.
     */
    public var suspendedState: MiPalState?

    /**
     *  The state that is set to `currentState` when the FSM is suspended.
     */
    public private(set) var suspendState: MiPalState

    internal init(
        name: String,
        initialState: MiPalState,
        ringlet: MiPalRinglet = MiPalRinglet(),
        initialPreviousState: MiPalState = MiPalState("_previous"),
        suspendedState: MiPalState? = nil,
        suspendState: MiPalState = MiPalState("_suspendState"),
        exitState: MiPalState = MiPalState("_exitState")
    ) {
        self.currentState = initialState
        self.exitState = exitState
        self.initialState = initialState
        self.ringlet = ringlet
        self.initialPreviousState = initialPreviousState
        self.name = name
        self.previousState = initialPreviousState
        self.suspendedState = suspendedState
        self.suspendState = suspendState
    }

    public func clone() -> CFSMFiniteStateMachine {
        var stateCache: [String: MiPalState] = [:]
        let allStates = self.allStates
        let fsm = CFSMFiniteStateMachine(
            name: self.name,
            initialState: self.initialState.clone(),
            ringlet: self.ringlet.clone(),
            initialPreviousState: self.initialPreviousState.clone(),
            suspendedState: self.suspendedState.map { $0.clone() },
            suspendState: self.suspendState.clone(),
            exitState: self.exitState.clone()
        )
        func apply(_ state: MiPalState) -> MiPalState {
            if let s = stateCache[state.name] {
                return s
            }
            let state = state
            stateCache[state.name] = state
            state.transitions = state.transitions.map {
                if $0.target == state {
                    return $0
                }
                guard let target = allStates[$0.target.name] else {
                    return $0
                }
                return $0.map { _ in apply(target.clone()) }
            }
            return state
        }
        fsm.initialState = apply(fsm.initialState)
        fsm.initialPreviousState = apply(fsm.initialPreviousState)
        fsm.suspendedState = fsm.suspendedState.map { apply($0) }
        fsm.suspendState = apply(fsm.suspendState)
        fsm.exitState = apply(fsm.exitState)
        fsm.currentState = apply(self.currentState.clone())
        fsm.previousState = apply(self.previousState.clone())
        return fsm
    }

}

extension CFSMFiniteStateMachine: CustomStringConvertible {

    var description: String {
        return """
            {
                name: \(self.name),
                initialState: \(self.initialState.name),
                currentState: \(self.currentState.name),
                previousState: \(self.previousState.name),
                suspendState: \(self.suspendState.name),
                suspendedState: \(self.suspendedState.map { $0.name } ?? "nil"),
                exitState: \(self.exitState.name),
                states: \(self.allStates)
            }
            """
    }

}

/*
 * ParameterisedFiniteStateMachine.swift 
 * FSM 
 *
 * Created by Callum McColl on 15/08/2018.
 * Copyright © 2018 Callum McColl. All rights reserved.
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
import KripkeStructure
import ModelChecking

/**
 *  A Parameterised Finite State Machine.
 *
 *  Finite State Machines (FSMs) are defined as an algorithm that can be in any
 *  number of a finite set of states.  Each state therefore represents a single
 *  situation that a Finite State Machine can be in, and executes certain logic.
 *
 *  An FSM must contain a state that is labelled the initial state, which
 *  represents where the FSM starts its execution.  The `initialState` property
 *  represents this state.
 *
 *  The actual execution logic is seperated into seperate types that conform to
 *  the `Ringlet` protocol.  The FSM therefore delegates the execution of its 
 *  states to `ringlet`.
 *
 *  The FSM keeps track of what to execute with the `currentState` and
 *  `previousState` properties.  The `currentState` represents the next state to
 *  execute and the `previousState` represents the last state that was executed.
 *  
 *  An FSM is capable of being suspended, in which case the FSM uses the 
 *  `suspendState` and `suspendedState`.  Instead of doing something similar to
 *  making `currentState` an optional state when we suspend, the FSM first sets
 *  the `suspendedState` to `currentState` and then sets `currentState` to
 *  `suspendState`.  `suspendState` therefore represents the state that is
 *  executed when the FSM is suspended.  The `suspendedState` represents the
 *  next state to execute once the FSM is resumed after being suspended.
 *
 *  An FSM is also a `VariablesContainer`.  Every state that is executed has
 *  access to FSM local variables, or rather variables that are shared amongst
 *  all the states of an FSM.  The FSM therefore stores these variables in
 *  `vars`.
 *  
 */
public struct ParameterisedFiniteStateMachine<
    R: Ringlet,
    KR: KripkePropertiesRecorder,
    V: VariablesContainer,
    P: VariablesContainer,
    RS: VariablesContainer,
    SM: ConvertibleToScheduleableFiniteStateMachine
>: ConvertibleToScheduleableFiniteStateMachine,
    ExitableStateExecuter,
    KripkePropertiesRecordable,
    KripkePropertiesRecorderDelegator,
    MutableSubmachinesContainer,
    OptimizedStateExecuter,
    ParametersContainerHolder,
    Restartable,
    ResumeableStateExecuter,
    ResultContainerHolder,
    ResultResettable,
    StateExecuterDelegator where
    RS.Vars: MutableResultContainer,
    R: Cloneable,
    R._StateType: Transitionable,
    R._StateType._TransitionType == Transition<R._StateType, R._StateType>,
    R._StateType: SnapshotListContainer,
    R._StateType: Cloneable,
    SM: Resumeable,
    SM: Restartable
{

    /**
     *  The type of the states.
     */
    public typealias _StateType = R._StateType

    public typealias Recorder = KR

    /**
     *  The state that is currently executing.
     */
    public var currentState: R._StateType

    public var currentRecord: KripkeStatePropertyList {
        var d: KripkeStatePropertyList = [
            "fsmVars": KripkeStateProperty(type: .Compound(
                self.recorder.takeRecord(of: self.fsmVars.vars)),
                value: self.fsmVars.vars
            ),
            "parameters": KripkeStateProperty(type:
                .Compound(self.recorder.takeRecord(of: self.parameters.vars)),
                value: self.parameters.vars
            ),
            "results": KripkeStateProperty(type:
                .Compound(self.recorder.takeRecord(of: self.results.vars)),
                value: self.results.vars
            ),
            "ringlet": KripkeStateProperty(type: .Compound(
                self.recorder.takeRecord(of: self.ringlet)),
                value: self.ringlet
            )
        ]
        var states: KripkeStatePropertyList = [:]
        var values: [String: R._StateType] = [:]
        self.allStates.forEach {
            states[$0] = KripkeStateProperty(type: .Compound(self.recorder.takeRecord(of: $1)), value: $1)
            values[$0] = $1
        }
        d["states"] = KripkeStateProperty(type: .Compound(states), value: values)
        return d
    }

    /**
     *  The state that is used to exit the FSM.
     */
    public let exitState: R._StateType

    public var externalVariables: [AnySnapshotController]
    
    public var sensors: [AnySnapshotController]
    
    public var actuators: [AnySnapshotController]

    public let fsmVars: V

    /**
     *  The initial state of the previous state.
     *
     *  `previousState` is set to this value on restart.
     */
    public let initialPreviousState: R._StateType

    /**
     *  The starting state of the FSM.
     */
    public let initialState: R._StateType

    /**
     *  The name of the FSM.
     *
     *  - Warning: This must be unique between FSMs.
     */
    public let name: String

    /**
     *  The parameters of the FSM.
     */
    public let parameters: P

    /**
     *  The last state that was executed.
     */
    public var previousState: R._StateType

    /**
     *  The `KripkePropertiesRecorder` responsible for recording all the
     *  variables used in formal verification.
     */
    public let recorder: Recorder

    public var results: RS

    /**
     *  An instance of `Ringlet` that is used to execute the states.
     */
    public fileprivate(set) var ringlet: R

    public var submachines: [SM]

    /**
     *  The state that was the `currentState` before the FSM was suspended.
     */
    public var suspendedState: R._StateType?

    /**
     *  The state that is set to `currentState` when the FSM is suspended.
     */
    public let suspendState: R._StateType

    /**
     *  Create a new `FiniteStateMachine`.
     *
     *  - Parameter name: The name of the FSM.
     *
     *  - Parameter initialState: The starting state of the FSM.
     *
     *  - Parameter ringlet: The `Ringlet` that will execute the states.
     *
     *  - Parameter initialPrevious: The starting value of `previousState`.
     *
     *  - Parameter suspendedState: The state that will be set to `currentState`
     *  once the FSM is resumed.  Setting this to a value that is not nil will
     *  force the FSM to be suspended.
     *
     *  - Parameter suspendState: The state that is set to `currentState` once
     *  the FSM is suspended.
     *
     *  - Parameter exitState: The state that is set to `currentState` once
     *  `exit()` is called.  This should be an accepting state.
     */
    public init(
        _ name: String,
        initialState: R._StateType,
        externalVariables: [AnySnapshotController],
        sensors: [AnySnapshotController],
        actuators: [AnySnapshotController],
        fsmVars: V,
        parameters: P,
        recorder: KR,
        results: RS,
        ringlet: R,
        initialPreviousState: R._StateType,
        suspendedState: R._StateType?,
        suspendState: R._StateType,
        exitState: R._StateType,
        submachines: [SM] = []
    ) {
        self.currentState = initialState
        self.exitState = exitState
        self.externalVariables = externalVariables
        self.sensors = sensors
        self.actuators = actuators
        self.fsmVars = fsmVars
        self.initialState = initialState
        self.initialPreviousState = initialPreviousState
        self.name = name
        self.parameters = parameters
        self.previousState = initialPreviousState
        self.recorder = recorder
        self.results = results
        self.ringlet = ringlet
        self.submachines = submachines
        self.suspendedState = suspendedState
        self.suspendState = suspendState
    }

    public func clone() -> ParameterisedFiniteStateMachine<R, KR, V, P, RS, SM>{
        var stateCache: [String: R._StateType] = [:]
        let allStates = self.allStates
        func apply(_ state: R._StateType) -> R._StateType {
            if let s = stateCache[state.name] {
                return s
            }
            var state = state
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
        self.fsmVars.vars = self.fsmVars.vars.clone()
        self.parameters.vars = self.parameters.vars.clone()
        self.results.vars = self.results.vars.clone()
        var fsm = ParameterisedFiniteStateMachine(
            self.name,
            initialState: apply(self.initialState.clone()),
            externalVariables: self.externalVariables,
            sensors: self.sensors,
            actuators: self.actuators,
            fsmVars: self.fsmVars,
            parameters: self.parameters,
            recorder: self.recorder,
            results: self.results,
            ringlet: self.ringlet.clone(),
            initialPreviousState: apply(self.initialPreviousState.clone()),
            suspendedState: self.suspendedState.map { apply($0.clone()) },
            suspendState: apply(self.suspendState.clone()),
            exitState: apply(self.exitState.clone()),
            submachines: self.submachines.map { $0.clone() }
        )
        fsm.currentState = apply(self.currentState.clone())
        fsm.previousState = apply(self.previousState.clone())
        fsm.allStates.forEach {
            _ = apply($1)
        }
        return fsm
    }

    public func resetResult() {
        self.results.vars.result = nil
    }

    fileprivate var allStates: [String: R._StateType] {
        var stateCache: [String: R._StateType] = [:]
        func fetchAllStates(fromState state: R._StateType) {
            if stateCache[state.name] != nil {
                return
            }
            stateCache[state.name] = state
            state.transitions.forEach {
                fetchAllStates(fromState: $0.target)
            }
        }
        fetchAllStates(fromState: self.initialState)
        return stateCache
    }

}

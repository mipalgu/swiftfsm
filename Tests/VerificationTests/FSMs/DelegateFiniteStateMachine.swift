/*
 * DelegateFiniteStateMachine.swift
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

import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm

final class DelegateFiniteStateMachine: MachineProtocol, CustomStringConvertible {
    
    typealias _StateType = MiPalState
    typealias Ringlet = MiPalRinglet
    
    var validVars: [String: [Any]] {
        [
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
            "calleeName": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "gateway": [],
            "timer": [],
            "sensors1": [],
            "$__lazy_storage_$_currentState": [],
            "$__lazy_storage_$_initialState": []
        ]
    }
    
    var description: String {
        "\(KripkeStatePropertyList(self))"
    }
    
    var computedVars: [String: Any] {
        return [
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }
    
    final class InitialState: MiPalState {
        
        override var validVars: [String : [Any]] {
            var dict = super.validVars
            dict["actualTransitions"] = []
            dict["callee"] = []
            return dict
        }
        
        var actualTransitions: [Transition<InitialState, MiPalState>]
        
        let callee: (Int) -> Promise<Bool>
        
        var promise: Promise<Bool>!
        
        init(_ name: String, transitions: [Transition<InitialState, MiPalState>] = [], snapshotSensors: Set<String>? = nil, snapshotActuators: Set<String>? = nil, callee: @escaping (Int) -> Promise<Bool>) {
            self.actualTransitions = transitions
            self.callee = callee
            let newTransitions = transitions.map { transition in
                Transition<MiPalState, MiPalState>(transition.target) {
                    transition.canTransition($0 as! InitialState)
                }
            }
            super.init(
                name,
                transitions: newTransitions,
                snapshotSensors: snapshotSensors,
                snapshotActuators: snapshotActuators
            )
        }
        
        override func onEntry() {
            promise = callee(5)
        }
        
        override func clone() -> InitialState {
            let state = InitialState(
                name, transitions: actualTransitions.map {
                    $0.map {
                        let clone = $0.clone()
                        return clone
                    }
                },
                callee: callee
            )
            state.promise = promise
            return state
        }
        
    }
    
    var gateway = StackGateway()
    
    var timer = FSMClock(ringletLengths: ["toggle": 10], scheduleLength: 10)
    
    var sensors: [AnySnapshotController] = []
    
    var actuators: [AnySnapshotController] = []
    
    var externalVariables: [AnySnapshotController] = []

    var name: String = "DelegateFiniteStateMachine"
    
    var calleeName: String = "CalleeFiniteStateMachine"
    
    var syncCall: Bool = true
    
    var value: Int = 0

    lazy var initialState: MiPalState = {
        InitialState(
            "initial",
            transitions: [Transition(exitState) { $0.promise.hasFinished }]
        ) { [unowned self] (value: Int) -> Promise<Bool> in
            let id = gateway.id(of: calleeName)
            let me = gateway.id(of: name)
            if syncCall {
                return gateway.call(id, withParameters: ["value": value], caller: me)
            } else {
                return gateway.invoke(id, withParameters: ["value": value], caller: me)
            }
        }
    }()

    lazy var currentState: MiPalState = { initialState }()
    
    var previousState: MiPalState = EmptyMiPalState("previous")
    
    var suspendedState: MiPalState? = nil
    
    var suspendState: MiPalState = EmptyMiPalState("suspend")
    
    var exitState: MiPalState = EmptyMiPalState("exit", snapshotSensors: [])
    
    var submachines: [SensorFiniteStateMachine] = []
    
    var initialPreviousState: MiPalState = EmptyMiPalState("previous")
    
    var ringlet = MiPalRinglet(previousState: EmptyMiPalState("previous"))

    func clone() -> DelegateFiniteStateMachine {
        let fsm = DelegateFiniteStateMachine()
        fsm.name = name
        fsm.calleeName = calleeName
        fsm.syncCall = syncCall
        fsm.initialState = initialState.clone()
        if currentState.name == initialState.name {
            fsm.currentState = fsm.initialState
        } else if currentState.name == exitState.name {
            fsm.currentState = fsm.exitState
        }
        if previousState.name == initialState.name {
            fsm.previousState = fsm.initialState
        } else if previousState.name == exitState.name {
            fsm.previousState = fsm.exitState
        }
        fsm.gateway = gateway
        fsm.timer = timer
        fsm.value = value
        fsm.ringlet = ringlet.clone()
        if fsm.ringlet.previousState.name == initialState.name {
            fsm.ringlet.previousState = fsm.initialState
        } else if fsm.ringlet.previousState.name == exitState.name {
            fsm.ringlet.previousState = fsm.exitState
        }
        return fsm
    }
    
    init() {}
    
    convenience init(value: Int, currentState: String, previousState: String) {
        self.init()
        if currentState == "initial" {
            self.currentState = self.initialState
        } else {
            self.currentState = EmptyMiPalState(currentState)
        }
        if previousState == "initial" {
            self.previousState = self.initialState
        } else {
            self.previousState = EmptyMiPalState(previousState)
        }
        self.value = value
        self.ringlet.previousState = self.previousState
        self.ringlet.shouldExecuteOnEntry = self.previousState != self.currentState
    }

}

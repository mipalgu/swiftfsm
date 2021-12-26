/*
 * SimpleTimeConditionalFiniteStateMachine.swift
 * VerificationTests
 *
 * Created by Callum McColl on 26/12/21.
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

final class SimpleTimeConditionalFiniteStateMachine: MachineProtocol, CustomStringConvertible {
    
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
            "sensors": Dictionary(uniqueKeysWithValues: sensors.map { ($0.name, $0.val) }),
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }
    
    var gateway = StackGateway()
    
    var timer = FSMClock(ringletLengths: ["toggle": 10], scheduleLength: 10)
    
    var sensors: [AnySnapshotController] = []
    
    var actuators: [AnySnapshotController] = []
    
    var externalVariables: [AnySnapshotController] = []

    var name: String = "SimpleTimeConditionalFiniteStateMachine"
    
    var value: Int = 0

    lazy var initialState: MiPalState = {
        CallbackMiPalState(
            "initial",
            transitions: [Transition(exitState) { [self] _ in timer.after_ms(20) }],
            snapshotSensors: [],
            snapshotActuators: [],
            main: { [self] in
                if timer.after_ms(25) {
                    value = 25
                } else if timer.after_ms(15) {
                    value = 15
                } else if timer.after_ms(5) {
                    value = 5
                }
            },
            onExit: { [self] in
                if timer.after_ms(25) {
                    value = 25
                } else if timer.after_ms(15) {
                    value = 15
                } else if timer.after_ms(5) {
                    value = 5
                }
            }
        )
    }()

    lazy var currentState: MiPalState = { initialState }()
    
    var previousState: MiPalState = EmptyMiPalState("previous")
    
    var suspendedState: MiPalState? = nil
    
    var suspendState: MiPalState = EmptyMiPalState("suspend")
    
    var exitState: MiPalState = EmptyMiPalState("exit", snapshotSensors: [])
    
    var submachines: [SensorFiniteStateMachine] = []
    
    var initialPreviousState: MiPalState = EmptyMiPalState("previous")
    
    var ringlet = MiPalRinglet(previousState: EmptyMiPalState("previous"))

    func clone() -> SimpleTimeConditionalFiniteStateMachine {
        let fsm = SimpleTimeConditionalFiniteStateMachine()
        fsm.name = name
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

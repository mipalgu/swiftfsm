/*
 * SensorFiniteStateMachine.swift
 * VerificationTests
 *
 * Created by Callum McColl on 28/11/21.
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

final class SensorFiniteStateMachine: MachineProtocol, CustomStringConvertible {
    
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
    
    var sensors1 = InMemoryContainer<Bool>(name: "sensors1", initialValue: false)
    
    var sensors: [AnySnapshotController] {
        get {
            [AnySnapshotController(sensors1)]
        } set {
            for sensor in sensors {
                if let val = newValue.first(where: { $0.name == sensor.name })?.val {
                    sensor.val = val
                }
            }
        }
    }
    
    var actuators: [AnySnapshotController] = []
    
    var externalVariables: [AnySnapshotController] = []

    var name: String = "SensorFiniteStateMachine"

    lazy var initialState: MiPalState = {
        CallbackMiPalState(
            "initial",
            transitions: [Transition(exitState) { [self] _ in sensors1.val }],
            snapshotSensors: [sensors1.name],
            snapshotActuators: []
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

    func clone() -> SensorFiniteStateMachine {
        let fsm = SensorFiniteStateMachine()
        fsm.name = name
        if currentState.name == initialState.name {
            fsm.currentState = fsm.initialState
        } else if currentState.name == exitState.name {
            fsm.currentState = fsm.exitState
        }
        fsm.sensors1.val = sensors1.val
        fsm.ringlet = ringlet.clone()
        return fsm
    }
    
    init() {}
    
    convenience init(sensorValue: Bool, currentState: String, previousState: String) {
        self.init()
        self.sensors1.val = sensorValue
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
        self.ringlet.previousState = self.previousState
        self.ringlet.shouldExecuteOnEntry = self.previousState != self.currentState
    }

}

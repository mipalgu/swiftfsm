/*
 * ExternalsFiniteStateMachine2.swift
 * 
 *
 * Created by Callum McColl on 9/7/21.
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

internal final class ExternalsFiniteStateMachine2: FiniteStateMachineType,
    Cloneable,
    ConvertibleToScheduleableFiniteStateMachine,
    StateExecuter,
    Exitable,
    Finishable,
    Resumeable,
    Restartable,
    Snapshotable,
    SnapshotControllerContainer,
    KripkeVariablesModifier
{
    
    var validVars: [String: [Any]] {
        [
            "gateway": [],
            "timer": [],
            "actuators": [],
            "sensors": [],
            "externalVariables": [],
            "initialState": [],
            "currentState": []
        ]
    }
    
    var computedVars: [String: Any] {
        [
            "actuators": Dictionary(uniqueKeysWithValues: actuators.map { ($0.name, $0.val) }),
            "sensors": Dictionary(uniqueKeysWithValues: sensors.map { ($0.name, $0.val) }),
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "initialState": initialState.name,
            "currentState": currentState.name
        ]
    }
    
    var gateway = StackGateway()
    
    var timer = FSMClock(ringletLengths: ["toggle": 10], scheduleLength: 10)
    
    var sensors: [AnySnapshotController] = [
        AnySnapshotController(InMemoryContainer<Bool>(name: "sensors1_2", initialValue: false)),
        AnySnapshotController(InMemoryContainer<Bool>(name: "sensors2_2", initialValue: false))
    ]
    
    var actuators: [AnySnapshotController] = [
        AnySnapshotController(InMemoryContainer<Bool>(name: "actuators1_2", initialValue: false)),
        AnySnapshotController(InMemoryContainer<Bool>(name: "actuators2_2", initialValue: false))
    ]
    
    var externalVariables: [AnySnapshotController] = [
        AnySnapshotController(InMemoryContainer<Bool>(name: "externals1_2", initialValue: false)),
        AnySnapshotController(InMemoryContainer<Bool>(name: "externals2_2", initialValue: false))
    ]

    //swiftlint:disable:next type_name
    typealias _StateType = MiPalState

    var name: String = "toggle_2"

    var initialState: MiPalState = EmptyMiPalState("initial")

    var currentState: MiPalState = EmptyMiPalState("current")

    let hasFinished: Bool = true

    let isSuspended: Bool = true

    let submachines: [AnyScheduleableFiniteStateMachine] = []

    func clone() -> ExternalsFiniteStateMachine2 {
        return self
    }

    func exit() {}

    func next() {
        (externalVariables + actuators).forEach {
            $0.val = !($0.val as! Bool)
        }
    }

    func restart() {}

    func resume() {}

    func saveSnapshot() {}

    func suspend() {}

}
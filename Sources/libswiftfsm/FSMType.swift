/*
 * FSMType.swift
 * swiftfsm
 *
 * Created by Callum McColl on 29/10/18.
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
import Functional
import KripkeStructure
import ModelChecking
import Utilities

//swiftlint:disable unused_setter_value

public enum FSMType {

    public var asControllableFiniteStateMachine: AnyControllableFiniteStateMachine? {
        switch self {
        case .controllableFSM(let fsm):
            return fsm
        case .parameterisedFSM:
            return nil
        }
    }

    public var asParameterisedFiniteStateMachine: AnyParameterisedFiniteStateMachine? {
        switch self {
        case .controllableFSM:
            return nil
        case .parameterisedFSM(let fsm):
            return fsm
        }
    }

    public var asScheduleableFiniteStateMachine: AnyScheduleableFiniteStateMachine {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.asScheduleableFiniteStateMachine
        case .parameterisedFSM(let fsm):
            return fsm.asScheduleableFiniteStateMachine
        }
    }

    case parameterisedFSM(AnyParameterisedFiniteStateMachine)

    case controllableFSM(AnyControllableFiniteStateMachine)

}

extension FSMType: Equatable {}

public func == (lhs: FSMType, rhs: FSMType) -> Bool {
    switch lhs {
    case .controllableFSM(let lfsm):
        switch rhs {
        case .controllableFSM(let rfsm):
            return lfsm == rfsm
        default:
            return false
        }
    case .parameterisedFSM(let lfsm):
        switch rhs {
        case .parameterisedFSM(let rfsm):
            return lfsm == rfsm
        default:
            return false
        }
    }
}

extension FSMType: ConvertibleToScheduleableFiniteStateMachine {

    public typealias _StateType = AnyState

    public var currentState: AnyState {
        get {
            switch self {
            case .controllableFSM(let fsm):
                return fsm.currentState
            case .parameterisedFSM(let fsm):
                return fsm.currentState
            }
        } set {}
    }

    public var externalVariables: [AnySnapshotController] {
        get {
            switch self {
            case .controllableFSM(let fsm):
                return fsm.externalVariables
            case .parameterisedFSM(let fsm):
                return fsm.externalVariables
            }
        } set {
            switch self {
            case .controllableFSM(var fsm):
                fsm.externalVariables = newValue
            case .parameterisedFSM(var fsm):
                fsm.externalVariables = newValue
                self = .parameterisedFSM(fsm)
            }
        }
    }
    
    public var sensors: [AnySnapshotController] {
        get {
            switch self {
            case .controllableFSM(let fsm):
                return fsm.sensors
            case .parameterisedFSM(let fsm):
                return fsm.sensors
            }
        } set {
            switch self {
            case .controllableFSM(var fsm):
                fsm.sensors = newValue
            case .parameterisedFSM(var fsm):
                fsm.sensors = newValue
            }
        }
    }
    
    public var actuators: [AnySnapshotController] {
        get {
            switch self {
            case .controllableFSM(let fsm):
                return fsm.actuators
            case .parameterisedFSM(let fsm):
                return fsm.actuators
            }
        } set {
            switch self {
            case .controllableFSM(var fsm):
                fsm.actuators = newValue
            case .parameterisedFSM(var fsm):
                fsm.actuators = newValue
            }
        }
    }
    
    public var snapshotSensors: [AnySnapshotController] {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.snapshotSensors
        case .parameterisedFSM(let fsm):
            return fsm.snapshotSensors
        }
    }
    
    public var snapshotActuators: [AnySnapshotController] {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.snapshotActuators
        case .parameterisedFSM(let fsm):
            return fsm.snapshotActuators
        }
    }

    public var hasFinished: Bool {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.hasFinished
        case .parameterisedFSM(let fsm):
            return fsm.hasFinished
        }
    }

    public var initialState: AnyState {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.initialState
        case .parameterisedFSM(let fsm):
            return fsm.initialState
        }
    }

    public var isSuspended: Bool {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.isSuspended
        case .parameterisedFSM(let fsm):
            return fsm.isSuspended
        }
    }

    public var name: String {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.name
        case .parameterisedFSM(let fsm):
            return fsm.name
        }
    }

    public var submachines: [AnyScheduleableFiniteStateMachine] {
        switch self {
        case .controllableFSM(let fsm):
            return fsm.submachines
        case .parameterisedFSM(let fsm):
            return fsm.submachines
        }
    }

    public func clone() -> FSMType {
        switch self {
        case .controllableFSM(let fsm):
            return .controllableFSM(fsm.clone())
        case .parameterisedFSM(let fsm):
            return .parameterisedFSM(fsm.clone())
        }
    }

    public mutating func next() {
        switch self {
        case .controllableFSM(let fsm):
            fsm.next()
        case .parameterisedFSM(let fsm):
            fsm.next()
        }
    }

    public mutating func suspend() {
        switch self {
        case .controllableFSM(let fsm):
            fsm.suspend()
        case .parameterisedFSM(let fsm):
            fsm.suspend()
        }
    }

    public func saveSnapshot() {
        switch self {
        case .controllableFSM(let fsm):
            fsm.saveSnapshot()
        case .parameterisedFSM(let fsm):
            fsm.saveSnapshot()
        }
    }

    public mutating func takeSnapshot() {
        switch self {
        case .controllableFSM(let fsm):
            fsm.takeSnapshot()
        case .parameterisedFSM(let fsm):
            fsm.takeSnapshot()
        }
    }

}

extension FSMType {

    public var parameters: Any? {
        switch self {
        case .parameterisedFSM(let fsm):
            return fsm.parameters
        default:
            return nil
        }
    }

    public var resultContainer: AnyResultContainer<Any>? {
        switch self {
        case .controllableFSM:
            return nil
        case .parameterisedFSM(let fsm):
            return fsm.resultContainer
        }
    }

}

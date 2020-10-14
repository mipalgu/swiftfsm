/*
 * AnyControllableFiniteStateMachine.swift 
 * FSM 
 *
 * Created by Callum McColl on 26/02/2018.
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

/**
 *  A type-erased Finite State Machine that can be controlled.
 *
 *  An instance of `AnyControllableFiniteStateMachine` forwards its operations
 *  to an underlying base `FiniteStateMachineType`, wrapping all states within
 *  an `AnyState`, hiding the specifics of the underlying fsm.
 *
 *  - SeeAlso: `AnyState`
 *  - SeeAlso: `FiniteStateMachineType`
 */
//swiftlint:disable:next colon
public struct AnyControllableFiniteStateMachine:
    FiniteStateMachineType,
    Cloneable,
    ConvertibleToScheduleableFiniteStateMachine,
    StateExecuter,
    Exitable,
    Finishable,
    Resumeable,
    Restartable,
    Snapshotable,
    SnapshotControllerContainer,
    SubmachinesContainer
{

    public typealias _StateType = AnyState

    public var base: Any {
        return self._base()
    }

    private let _asScheduleableFiniteStateMachine: () -> AnyScheduleableFiniteStateMachine

    private let _base: () -> Any

    private let _clone: () -> AnyControllableFiniteStateMachine

    private let _currentState: () -> AnyState

    private let _exit: () -> Void

    private let _externalVariables: () -> [AnySnapshotController]

    private let _setExternalVariables: ([AnySnapshotController]) -> Void
    
    private let _sensors: () -> [AnySnapshotController]
    
    private let _setSensors: ([AnySnapshotController]) -> Void
    
    private let _actuators: () -> [AnySnapshotController]
    
    private let _setActuators: ([AnySnapshotController]) -> Void
    
    private let _snapshotSensors: () -> [AnySnapshotController]
    
    private let _snapshotActuators: () -> [AnySnapshotController]

    private let _hasFinished: () -> Bool

    private let _initialState: () -> AnyState

    private let _isSuspended: () -> Bool

    private let _name: () -> String

    private let _next: () -> Void

    private let _restart: () -> Void

    private let _resume: () -> Void

    private let _submachines: () -> [AnyScheduleableFiniteStateMachine]

    private let _suspend: () -> Void

    private let _saveSnapshot: () -> Void

    private let _takeSnapshot: () -> Void

    //private let _update: ([String: Any]) -> Void

    public var asScheduleableFiniteStateMachine: AnyScheduleableFiniteStateMachine {
        return self._asScheduleableFiniteStateMachine()
    }

    /**
     *  The next state to execute.
     *
     *  - Attention: This state is read-only, attempting to set this to a new
     *  value will not do anything.
     */
    public var currentState: AnyState {
        get {
            return self._currentState()
        } set {}
    }

    public var externalVariables: [AnySnapshotController] {
        get {
            return self._externalVariables()
        } set {
            self._setExternalVariables(newValue)
        }
    }
    
    public var sensors: [AnySnapshotController] {
        get {
            return self._sensors()
        } set {
            self._setSensors(newValue)
        }
    }
    
    public var actuators: [AnySnapshotController] {
        get {
            return self._actuators()
        } set {
            self._setSensors(newValue)
        }
    }
    
    public var snapshotSensors: [AnySnapshotController] {
        return self._snapshotSensors()
    }
    
    public var snapshotActuators: [AnySnapshotController] {
        return self._snapshotActuators()
    }

    /**
     *  Has the Finite State Machine finished?
     */
    public var hasFinished: Bool {
        return self._hasFinished()
    }

    /**
     *  The first state that the Finite State Machine would execute.
     */
    public var initialState: AnyState {
        return self._initialState()
    }

    /**
     *  Is the Finite State Machine suspended?
     */
    public var isSuspended: Bool {
        return self._isSuspended()
    }

    /**
     *  The name of the Finite State Machine.
     *
     *  - Warning: This must be unique between Finite State Machines.
     */
    public var name: String {
        return self._name()
    }

    public var submachines: [AnyScheduleableFiniteStateMachine] {
        return self._submachines()
    }

    internal init<FSM: ConvertibleToScheduleableFiniteStateMachine>(_ ref: Ref<FSM>) where
        FSM: Exitable,
        FSM: Resumeable,
        FSM: Restartable
    {
        self._asScheduleableFiniteStateMachine = { AnyScheduleableFiniteStateMachine(ref) }
        self._base = { ref.value as Any }
        self._clone = { AnyControllableFiniteStateMachine(ref.value.clone()) }
        self._currentState = { AnyState(ref.value.currentState) }
        self._exit = { ref.value.exit() }
        self._setExternalVariables = { ref.value.externalVariables = $0 }
        self._externalVariables = { ref.value.externalVariables }
        self._sensors = { ref.value.sensors }
        self._setSensors = { ref.value.sensors = $0 }
        self._actuators = { ref.value.actuators }
        self._setActuators = { ref.value.actuators = $0 }
        self._snapshotSensors = { ref.value.snapshotSensors }
        self._snapshotActuators = { ref.value.snapshotActuators }
        self._hasFinished = { ref.value.hasFinished }
        self._initialState = { AnyState(ref.value.initialState) }
        self._isSuspended = { ref.value.isSuspended }
        self._name = { ref.value.name }
        self._next = { ref.value.next() }
        self._restart = { ref.value.restart() }
        self._resume = { ref.value.resume() }
        self._submachines = { ref.value.submachines.map { AnyScheduleableFiniteStateMachine($0) } }
        self._suspend = { ref.value.suspend() }
        self._saveSnapshot = { ref.value.saveSnapshot() }
        self._takeSnapshot = { ref.value.takeSnapshot() }
        //self._update = { ref.value.update(fromDictionary: $0) }
    }

    /**
     *  Creates a new `AnyScheduleableFiniteStateMachine` that wraps and
     *  forwards operations to `base`.
     */
    public init<FSM: ConvertibleToScheduleableFiniteStateMachine>(_ base: FSM) where
        FSM: Exitable,
        FSM: Resumeable,
        FSM: Restartable
    {
        let ref = Ref(value: base)
        self.init(ref)
    }

    public func clone() -> AnyControllableFiniteStateMachine {
        return self._clone()
    }

    /**
     *  Stop the Finite State Machine from running.
     *
     *  - Postcondition: `hasFinished` is true.
     */
    public func exit() {
        self._exit()
    }

    /**
     *  Execute the next state.
     */
    public func next() {
        self._next()
    }

    /**
     *  Restart the Finite State Machine.
     */
    public func restart() {
        self._restart()
    }

    /**
     *  Resume the Finite State Machine so that it is no longer suspended.
     */
    public func resume() {
        self._resume()
    }

    /**
     *  Suspend the Finite State Machine.
     */
    public func suspend() {
        self._suspend()
    }

    public func saveSnapshot() {
        self._saveSnapshot()
    }

    public func takeSnapshot() {
        self._takeSnapshot()
    }

    /*public func update(fromDictionary dictionary: [String: Any]) {
        self._update(dictionary)
    }*/

 }

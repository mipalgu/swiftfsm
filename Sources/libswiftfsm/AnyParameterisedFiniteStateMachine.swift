/*
 * AnyParameterisedFiniteStateMachine.swift 
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
import Utilities

//swiftlint:disable unused_setter_value

//swiftlint:disable:next colon
public struct AnyParameterisedFiniteStateMachine:
    FiniteStateMachineType,
    Cloneable,
    ConvertibleToScheduleableFiniteStateMachine,
    StateExecuter,
    Finishable,
    Restartable,
    Snapshotable,
    SnapshotControllerContainer,
    Suspendable,
    ResultResettable
{

    public typealias _StateType = AnyState

    public var base: Any {
        return self._base()
    }

    private let _asScheduleableFiniteStateMachine: () -> AnyScheduleableFiniteStateMachine

    private let _base: () -> Any

    private let _clone: () -> AnyParameterisedFiniteStateMachine

    private let _currentState: () -> AnyState

    private let _externalVariables: () -> [AnySnapshotController]

    private let _setExternalVariables: ([AnySnapshotController]) -> Void
    
    private let _sensors: () -> [AnySnapshotController]
    
    private let _setSensors: ([AnySnapshotController]) -> Void
    
    private let _actuators: () -> [AnySnapshotController]
    
    private let _setActuators: ([AnySnapshotController]) -> Void
    
    private let _snapshotSensors: () -> [AnySnapshotController]
    
    private let _snapshotActuators: () -> [AnySnapshotController]

    private let _getParameters: () -> Any

    private let _hasFinished: () -> Bool

    private let _initialState: () -> AnyState

    private let _isSuspended: () -> Bool

    private let _name: () -> String

    private let _next: () -> Void

    private let _restart: () -> Void

    private let _resetResult: () -> Void

    private let _resultContainer: () -> AnyResultContainer<Any>

    private let _setParameters: (Any) -> Void

    private let _setParametersFromDictionary: ([String: Any]) -> Bool

    private let _setParametersFromStringDictionary: ([String: String]) -> Bool

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

    public var parameters: Any {
        return self._getParameters()
    }

    public var resultContainer: AnyResultContainer<Any> {
        return self._resultContainer()
    }

    public var submachines: [AnyScheduleableFiniteStateMachine] {
        return self._submachines()
    }

    internal init<FSM: ConvertibleToScheduleableFiniteStateMachine>(_ ref: Ref<FSM>) where
        FSM: Restartable,
        FSM: ResultContainerHolder,
        FSM: ParametersContainerHolder,
        FSM: ResultResettable,
        FSM.ParametersContainerType.Vars: DictionaryConvertible,
        FSM.ParametersContainerType.Vars: ConvertibleFromDictionary
    {
        self._asScheduleableFiniteStateMachine = { AnyScheduleableFiniteStateMachine(ref) }
        self._base = { ref.value as Any }
        self._clone = { AnyParameterisedFiniteStateMachine(ref.value.clone()) }
        self._currentState = { AnyState(ref.value.currentState) }
        self._setExternalVariables = { ref.value.externalVariables = $0 }
        self._externalVariables = { ref.value.externalVariables }
        self._sensors = { ref.value.sensors }
        self._setSensors = { ref.value.sensors = $0 }
        self._actuators = { ref.value.actuators }
        self._setActuators = { ref.value.actuators = $0 }
        self._snapshotSensors = { ref.value.snapshotSensors }
        self._snapshotActuators = { ref.value.snapshotActuators }
        self._getParameters = { ref.value.parameters.vars }
        self._hasFinished = { ref.value.hasFinished }
        self._initialState = { AnyState(ref.value.initialState) }
        self._isSuspended = { ref.value.isSuspended }
        self._name = { ref.value.name }
        self._next = { ref.value.next() }
        self._setParametersFromDictionary = {
            let params = FSM.ParametersContainerType.Vars(fromDictionary: $0)
            ref.value.parameters.vars = params
            return true
        }
        self._setParametersFromStringDictionary = {
            guard let params = FSM.ParametersContainerType.Vars($0) else {
                return false
            }
            ref.value.parameters.vars = params
            return true
        }
        self._setParameters = {
            guard let parameters = $0 as? FSM.ParametersContainerType.Vars else {
                fatalError("Attempting to set parameters of \(ref.value.name) with an incorrect parameter type.")
            }
            ref.value.parameters.vars = parameters
        }
        self._resetResult = { ref.value.resetResult() }
        self._restart = { ref.value.restart() }
        self._resultContainer = { AnyResultContainer<Any>({ ref.value.results.vars.result as Any? }) }
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
        FSM: Restartable,
        FSM: ResultContainerHolder,
        FSM: ParametersContainerHolder,
        FSM: ResultResettable,
        FSM.ParametersContainerType.Vars: DictionaryConvertible,
        FSM.ParametersContainerType.Vars: ConvertibleFromDictionary
    {
        let ref = Ref(value: base)
        self.init(ref)
    }

    public func clone() -> AnyParameterisedFiniteStateMachine {
        return self._clone()
    }

    /**
     *  Execute the next state.
     */
    public func next() {
        self._next()
    }

    public func resetResult() {
        self._resetResult()
    }

    public func restart() {
        self._restart()
    }

    public func setParameters<P: Variables>(_ newParameters: P) {
        self._setParameters(newParameters)
    }

    public func parametersFromDictionary(_ dictionary: [String: Any]) -> Bool {
        return self._setParametersFromDictionary(dictionary)
    }

    public func parametersFromStringDictionary(_ dictionary: [String: String]) -> Bool {
        return self._setParametersFromStringDictionary(dictionary)
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

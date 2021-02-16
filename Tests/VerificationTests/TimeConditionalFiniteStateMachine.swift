/*
 * TimeConditionalFiniteStateMachine.swift
 * VerificationTests
 *
 * Created by Callum McColl on 16/2/21.
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
import Gateways
import Timers
import KripkeStructure
import Verification
import swiftfsm

internal final class TimeConditionalFiniteStateMachine: ParameterisedMachineProtocol, KripkeVariablesModifier
{
    
    typealias RingletType = MiPalRinglet
    
    final class ParametersContainerType: VariablesContainer {
        
        final class Vars: Variables, ConvertibleFromDictionary, DictionaryConvertible {
            
            var value: Bool
            
            init(value: Bool = false) {
                self.value = value
            }
            
            convenience init?(_ dictionary: [String : String]) {
                guard let str = dictionary["value"], let value = Bool(str) else {
                    return nil
                }
                self.init(value: value)
            }
            
            convenience init(fromDictionary dictionary: [String : Any?]) {
                guard let value = dictionary["value"] as? Bool else {
                    fatalError("Unable to fetch value from dictionary.")
                }
                self.init(value: value)
            }
            
            func clone() -> Vars {
                return Vars(value: value)
            }
        }
        
        var vars: Vars
        
        init(vars: Vars = Vars()) {
            self.vars = vars
        }
        
    }
    
    final class ResultContainerType: VariablesContainer {
        
        final class Vars: Variables, ConvertibleFromDictionary, ResultContainer {
            
            var result: Bool?
            
            init(result: Bool? = nil) {
                self.result = result
            }
            
            convenience init(fromDictionary dictionary: [String : Any?]) {
                guard let result = dictionary["value"] as? Bool? else {
                    fatalError("Unable to fetch value from dictionary.")
                }
                self.init(result: result)
            }
            
            func clone() -> Vars {
                return Vars(result: self.result)
            }
        }
        
        var vars: Vars
        
        init(vars: Vars = Vars()) {
            self.vars = vars
        }
        
    }
    
    public var validVars: [String : [Any]] {
        [
            "gateway": [],
            "timer": [],
            "exitState": [],
            "initialPreviousState": [],
            "previousState": [],
            "suspendedState": [],
            "suspendState": [],
            "sensors": [],
            "actuators": [],
            "initialState": [],
            "currentState": [],
            "externalVariables": [],
            "hasFinished": [],
            "isSuspended": [],
            "submachines": []
        ]
    }
    
    func resetResult() {
        self.results.vars = ResultContainerType.Vars()
    }
    
    private(set) var gateway = StackGateway()
    
    private(set) var timer = FSMClock(ringletLengths: ["conditional": 10], scheduleLength: 10)
    
    var ringlet: MiPalRinglet = MiPalRinglet()
    
    var parameters: ParametersContainerType = ParametersContainerType()
    
    var results: ResultContainerType = ResultContainerType()
    
    var exitState: MiPalState = EmptyMiPalState("exitState")
    
    var initialPreviousState: MiPalState = EmptyMiPalState("initialPrevious")
    
    var previousState: MiPalState = EmptyMiPalState("previous")
    
    var suspendedState: MiPalState? = nil
    
    var suspendState: MiPalState = EmptyMiPalState("suspendState")
    
    var sensors: [AnySnapshotController] = []
    
    var actuators: [AnySnapshotController] = []

    //swiftlint:disable:next type_name
    typealias _StateType = MiPalState

    let name: String = "conditional"

    var initialState: MiPalState = EmptyMiPalState("initial")
    
    var value: Bool = false

    lazy var currentState: MiPalState = {
        CallbackMiPalState("Call", onEntry: { [unowned self] in
            if self.timer.after(2) {
                let id = self.gateway.id(of: self.name)
                let _: Promise<Bool> = self.gateway.call(id, withParameters: ["value": true], caller: id)
            } else if self.timer.after(3) {
                // do nothing.
            } else {
                self.value.toggle()
            }
        })
    }()

    var externalVariables: [AnySnapshotController] = []

    let hasFinished: Bool = true

    let isSuspended: Bool = true

    var submachines: [AnyScheduleableFiniteStateMachine] = []

    func clone() -> TimeConditionalFiniteStateMachine {
        let clone = TimeConditionalFiniteStateMachine()
        clone.timer = timer
        clone.gateway = gateway
        clone.value = value
        return clone
    }
    
    func restart() {}
    
    func resume() {}

}

/*
 * WorldCreator.swift
 * Verification
 *
 * Created by Callum McColl on 10/9/18.
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
import MachineStructure
import ModelChecking
import swiftfsm

public final class WorldCreator {
    
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    
    public init() {}
    
    //swiftlint:disable:next function_parameter_count
    public func createWorld(
        fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andParameterisedMachines parameterisedMachines: [FSM_ID: ParameterisedMachineData],
        andTokens tokens: [[VerificationToken]],
        andLastState lastState: KripkeState?,
        andExecuting executing: Int,
        andExecutingToken token: Int,
        withState state: String,
        usingCallStack callStack: [FSM_ID: [CallData]],
        worldType: WorldType
    ) -> KripkeStatePropertyList {
        let externalVariables = self.convert(externals: externals, withLastState: lastState)
        let str: String
        switch worldType {
        case .beforeExecution:
            str = "R"
        case .afterExecution:
            str = "W"
        }
        let varPs = self.convert(
            tokens: tokens,
            executing: executing,
            executingToken: token,
            withState: state,
            appendingToPC: str
        )
        var total: [String: KripkeStateProperty] = lastState?.properties.properties ?? [:]
        for (key, val) in varPs.properties {
            total[key] = val
        }
        for (key, val) in externalVariables.properties {
            total[key] = val
        }
        for (key, val) in self.createCallProperties(forParameterisedMachines: parameterisedMachines, withCallStack: callStack) {
            total[key] = val
        }
        return KripkeStatePropertyList(total)
        //return (lastState?.properties ?? [:]) <| varPs <| externalVariables
    }
    
    fileprivate func createCallProperties(forParameterisedMachines parameterisedMachines: [FSM_ID: ParameterisedMachineData], withCallStack callStack: [FSM_ID: [CallData]]) -> KripkeStatePropertyList {
        var props: KripkeStatePropertyList = [:]
        var values: [String: Any] = [:]
        var out: KripkeStatePropertyList = [:]
        for (id, data) in parameterisedMachines {
            var inner: KripkeStatePropertyList = [:]
            var innerValues: [String: Any] = [:]
            guard let callData = callStack[id]?.last else {
                func convertProperty(_ property: KripkeStateProperty) -> KripkeStateProperty {
                    switch property.type {
                    case .EmptyCollection:
                        return property
                    case .Collection(let properties):
                        let converted = properties.map(convertProperty)
                        return KripkeStateProperty(type: .Collection(converted), value: converted.map { $0.value })
                    case .Compound(let list):
                        return KripkeStateProperty(type: .Compound(setNil(list)), value: [:])
                    default:
                        return KripkeStateProperty(type: .String, value: "nil")
                    }
                }
                func setNil(_ parameterList: KripkeStatePropertyList) -> KripkeStatePropertyList {
                    var list: [String: KripkeStateProperty] = [:]
                    list.reserveCapacity(parameterList.count)
                    for (name, property) in parameterList {
                        list[name] = convertProperty(property)
                    }
                    return KripkeStatePropertyList(list)
                }
                let parameterList = self.recorder.takeRecord(of: data.fsm.parameters)
                inner["parameters"] = KripkeStateProperty(type: .Compound(setNil(parameterList)), value: data.fsm.parameters)
                inner["hasFinished"] = KripkeStateProperty(type: .Bool, value: false)
                innerValues["hasFinished"] = false
                let (type, value) = self.recorder.getKripkeStatePropertyType(data.fsm.resultContainer.result)
                inner["result"] = KripkeStateProperty(type: .String, value: "nil")
                innerValues["result"] = "nil"
                inner["runCount"] = KripkeStateProperty(type: .UInt, value: UInt(0))
                innerValues["runCount"] = 0
                props[data.fullyQualifiedName] = KripkeStateProperty(type: .Compound(inner), value: innerValues)
                values[data.fullyQualifiedName] = innerValues
                continue
            }
            inner["parameters"] = KripkeStateProperty(type: .Compound(self.recorder.takeRecord(of: callData.parameters)), value: callData.parameters)
            inner["hasFinished"] = KripkeStateProperty(type: .Bool, value: callData.promiseData.hasFinished)
            innerValues["hasFinished"] = callData.promiseData.hasFinished
            if nil == callData.promiseData.result {
                inner["result"] = KripkeStateProperty(type: .String, value: "nil")
                innerValues["result"] = "nil"
            } else {
                let (type, value) = self.recorder.getKripkeStatePropertyType(callData.promiseData.result)
                inner["result"] = KripkeStateProperty(type: type, value: value)
                innerValues["result"] = value
            }
            inner["runCount"] = KripkeStateProperty(type: .UInt, value: callData.runs)
            innerValues["runCount"] = callData.runs
            props[callData.fullyQualifiedName] = KripkeStateProperty(type: .Compound(inner), value: innerValues)
            values[callData.fullyQualifiedName] = innerValues
        }
        out["parameterisedMachines"] = KripkeStateProperty(type: .Compound(props), value: values)
        return out
    }
    
    fileprivate func fetchLastExternals(fromLastState lastState: KripkeState?) -> KripkeStatePropertyList {
        guard let externalsProperty = lastState?.properties.properties["externalVariables"] else {
            return [:]
        }
        switch externalsProperty.type {
        case .Compound(let props):
            return props
        default:
            return [:]
        }
    }
    
    private func convert(externals: [(AnySnapshotController, KripkeStatePropertyList)], withLastState lastState: KripkeState?) -> KripkeStatePropertyList {
        let lastExternals = self.fetchLastExternals(fromLastState: lastState)
        var props: KripkeStatePropertyList = [:]
        var values: [String: Any] = [:]
        externals.forEach {
            props[$0.0.name] = KripkeStateProperty(type: .Compound($0.1), value: $0.0.val)
            values[$0.0.name] = $0.0.val
        }
        return [
            "externalVariables": KripkeStateProperty(
                type: .Compound(lastExternals.merged(props)),
                value: values
            )
        ]
    }
    
    private func convert(
        tokens: [[VerificationToken]],
        executing: Int,
        executingToken token: Int,
        withState state: String,
        appendingToPC str: String
    ) -> KripkeStatePropertyList {
        var varPs: KripkeStatePropertyList = [:]
        guard let pcTokenData = tokens[executing][token].data else {
            return varPs
        }
        tokens.forEach {
            $0.forEach {
                guard let data = $0.data else {
                    return
                }
                varPs[data.fsm.name] = KripkeStateProperty(
                    type: .Compound(self.recorder.takeRecord(of: data.fsm.asScheduleableFiniteStateMachine.base)),
                    value: data.fsm
                )
            }
        }
        varPs["pc"] = KripkeStateProperty(
            type: .String,
            value: self.createPC(ofTokenData: pcTokenData, withState: state, appending: str)
        )
        return varPs
    }
    
    fileprivate func createPC(
        ofTokenData data: VerificationToken.Data,
        withState state: String,
        appending str: String
    ) -> String {
        return "\(data.fsm.name).\(state).\(str)"
    }
    
}

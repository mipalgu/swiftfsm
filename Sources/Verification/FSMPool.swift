/*
 * FSMPool.swift
 * Verification
 *
 * Created by Callum McColl on 20/11/21.
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

import swiftfsm
import KripkeStructure
import FSM
import Gateways
import swift_helpers

public struct FSMPool {

    struct ParameterisedStatus: KripkeVariablesModifier {

        enum Status: String, Hashable, Codable {

            case inactive
            case executing

        }

        struct CallData {

            var parameters: [String: Any?]

            var result: Any?

            var cloned: CallData {
                CallData(
                    parameters: parameters.mapValues { ($0 as? Cloneable)?.clone() ?? $0 },
                    result: (result as? Cloneable)?.clone() ?? result
                )
            }

        }

        var computedVars: [String : Any] {
            [
                "parameters": call?.parameters ?? Optional<[String: Any?]>.none as Any,
                "result": call?.result ?? Optional<Any?>.none as Any
            ]
        }

        var validVars: [String : [Any]] {
            ["call": []]
        }

        var status: Status

        var call: CallData?

        var cloned: ParameterisedStatus {
            ParameterisedStatus(status: status, call: call?.cloned)
        }

    }

    var parameterisedFSMs: [String: ParameterisedStatus]
    
    private(set) var fsms: [FSMType]
    
    private var indexes: [String: FSM_ID]
    
    var cloned: FSMPool {
        FSMPool(fsms: fsms.map { $0.clone() }, indexes: indexes, parameterisedFSMs: parameterisedFSMs.mapValues(\.cloned))
    }
    
    private init(fsms: [FSMType], indexes: [String: FSM_ID], parameterisedFSMs: [String: ParameterisedStatus]) {
        self.fsms = fsms
        self.indexes = indexes
        self.parameterisedFSMs = parameterisedFSMs
    }
    
    init(fsms: [FSMType], parameterisedFSMs: Set<String>) {
        self.init(
            fsms: fsms,
            indexes: Dictionary(uniqueKeysWithValues: fsms.enumerated().map { ($1.name, $0) }),
            parameterisedFSMs: Dictionary(uniqueKeysWithValues: parameterisedFSMs.map {
                ($0, ParameterisedStatus(status: .inactive, call: nil))
            })
        )
    }
    
    mutating func insert(_ fsm: FSMType) {
        guard let index = indexes[fsm.name] else {
            let index = fsms.count
            fsms.append(fsm)
            indexes[fsm.name] = index
            return
        }
        fsms[index] = fsm
    }
    
    func has(_ name: String) -> Bool {
        return indexes[name] != nil
    }

    func hasThatIsntDelegate(_ name: String) -> Bool {
        if parameterisedFSMs[name] != nil {
            return false
        }
        return has(name)
    }
    
    func index(of name: String) -> FSM_ID {
        guard let index = indexes[name] else {
            print(name)
            print(indexes)
            fatalError("Attempting to fetch index of fsm that doesn't exist within the pool.")
        }
        return index
    }
    
    func fsm(atIndex index: Int) -> FSMType {
        return fsms[index]
    }
    
    func fsm(_ name: String) -> FSMType {
        return fsm(atIndex: index(of: name))
    }

    func setPromises(_ promises: [String: PromiseData]) -> [PromiseSnapshot] {
        var setPromises: [PromiseSnapshot] = []
        setPromises.reserveCapacity(promises.count)
        for (callee, promise) in promises {
            guard let status = parameterisedFSMs[callee], status.status == .inactive, let call = status.call else {
                continue
            }
            let snapshot = PromiseSnapshot(promiseData: promise)
            setPromises.append(snapshot)
            promise._hasFinished = true
            promise.result = call.result
        }
        return setPromises
    }

    func undoSetPromises(_ promises: [PromiseSnapshot]) {
        for promise in promises {
            promise.apply()
        }
    }
    
    func propertyList(forStep step: VerificationStep, executingState state: String?, promises: [String: PromiseData], resetClocks: Set<String>?, collapseIfPossible collapse: Bool = false) -> KripkeStatePropertyList {
        let setPromises = setPromises(promises)
        var fsmValues: [String: KripkeStateProperty] = Dictionary(uniqueKeysWithValues: fsms.compactMap {
            guard !parameterisedFSMs.keys.contains($0.name) else {
                return nil
            }
            return ($0.name, KripkeStateProperty(type: .Compound(KripkeStatePropertyList($0.asScheduleableFiniteStateMachine.base)), value: $0.asScheduleableFiniteStateMachine.base))
        })
        fsmValues.reserveCapacity(fsmValues.count + parameterisedFSMs.count)
        for (key, val) in parameterisedFSMs {
            guard val.status == .executing, let call = val.call else {
                fsmValues[key] = KripkeStateProperty(type: .Optional(nil), value: Optional<[String: Any]>.none as Any)
                continue
            }
            fsmValues[key] = KripkeStateProperty(
                type: .Optional(KripkeStateProperty(
                    type: .Compound(KripkeStatePropertyList([
                        "parameters": .init(
                            type: .Compound(KripkeStatePropertyList(call.parameters.mapValues { KripkeStateProperty($0 as Any) })),
                            value: call.parameters
                        ),
                        "result": KripkeStateProperty(call.result)
                    ])),
                    value: call
                )),
                value: Optional<ParameterisedStatus.CallData>.some(call) as Any
            )
        }
        undoSetPromises(setPromises)
        let clocks: KripkeStateProperty? = resetClocks.map { resetClocks in
            let values = Dictionary(uniqueKeysWithValues: fsmValues.keys.map {
                ($0, resetClocks.contains($0))
            })
            let props = values.mapValues {
                KripkeStateProperty(type: .Bool, value: $0)
            }
            return KripkeStateProperty(type: .Compound(KripkeStatePropertyList(properties: props)), value: values)
        }
        var dict = [
            "fsms": KripkeStateProperty(type: .Compound(KripkeStatePropertyList(properties: fsmValues)), value: fsmValues.mapValues(\.value)),
            "pc": step.property(state: state, collapseIfPossible: collapse)
        ]
        dict["resetClocks"] = clocks
        return KripkeStatePropertyList(properties: dict)
    }

    mutating func handleCall(to fsm: String, parameters: [String: Any?]) {
        var status = self.parameterisedFSMs[fsm] ?? ParameterisedStatus(
            status: .inactive,
            call: nil
        )
        guard status.status == .inactive else {
            fatalError("Detected call to fsm that is already executing.")
        }
        status.status = .executing
        status.call = ParameterisedStatus.CallData(parameters: parameters, result: nil)
        self.parameterisedFSMs[fsm] = status
    }

    mutating func handleFinishedCall(for fsm: String, result: Any?) {
        guard var status = self.parameterisedFSMs[fsm], status.status == .executing, status.call != nil else {
            fatalError("Detected finishing call to fsm that has not been executing.")
        }
        status.status = .inactive
        status.call?.result = result
        self.parameterisedFSMs[fsm] = status
    }

    mutating func setInactive(_ fsm: String) {
        self.parameterisedFSMs[fsm]?.status = .inactive
        self.parameterisedFSMs[fsm]?.call = nil
    }
    
}

extension FSMPool: Hashable {
    
    public static func ==(lhs: FSMPool, rhs: FSMPool) -> Bool {
        lhs.fsms.map { KripkeStatePropertyList($0.asScheduleableFiniteStateMachine.base) } == rhs.fsms.map { KripkeStatePropertyList($0.asScheduleableFiniteStateMachine.base) }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fsms.map { KripkeStatePropertyList($0.asScheduleableFiniteStateMachine.base) })
    }
    
}

extension FSMPool: CustomStringConvertible {
    
    public var description: String {
        fsms.sorted { $0.name < $1.name }.map(\.asScheduleableFiniteStateMachine).map {
            $0.name + ": \($0.base)"
        }.joined(separator: "\n")
    }
    
}

/*
 * VerificationCycleExecuter.swift
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
import swiftfsm
import swiftfsm_helpers

public final class VerificationCycleExecuter {
    
    fileprivate let executer: VerificationTokenExecuter<KripkeStateGenerator>
    
    public init(executer: VerificationTokenExecuter<KripkeStateGenerator> = VerificationTokenExecuter(stateGenerator: KripkeStateGenerator())) {
        self.executer = executer
    }
    
    fileprivate struct Job {
        
        let index: Int
        
        let tokens: [[VerificationToken]]
        
        let externals: [(AnySnapshotController, KripkeStatePropertyList)]
        
        let lastState: KripkeState?
        
        let clock: UInt
        
    }
    
    public func execute(
        tokens: [[VerificationToken]],
        executing: Int,
        withExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andLastState last: KripkeState?
    ) -> [KripkeState] {
        var last = last
        //swiftlint:disable:next line_length
        var jobs = [Job(index: 0, tokens: tokens, externals: externals, lastState: last, clock: 0)]
        var states: [KripkeState] = []
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            job.tokens[executing].forEach {
                var fsm = $0.fsm
                fsm.externalVariables.enumerated().forEach { (offset, externalVariables) in
                    guard let (external, props) = externals.first(where: { $0.0.name == externalVariables.name }) else {
                        return
                    }
                    fsm.externalVariables[offset].val = fsm.externalVariables[offset].create(fromDictionary: self.convert(props))
                }
            }
            let clone = job.tokens[executing][job.index].fsm.clone()
            let (generatedStates, clockValues, newExternals) = self.executer.execute(
                fsm: clone,
                inTokens: job.tokens,
                executing: executing,
                atOffset: job.index,
                withExternals: job.externals,
                andClock: job.clock,
                andLastState: job.lastState
            )
            states.append(contentsOf: generatedStates)
            jobs.append(contentsOf: clockValues.map {
                Job(index: job.index, tokens: job.tokens, externals: externals, lastState: job.lastState, clock: $0 + 1)
            })
            if job.index + 1 >= tokens[executing].count {
                continue
            }
            var newTokens = job.tokens
            newTokens[executing][job.index] = VerificationToken(fsm: clone, machine: job.tokens[executing][job.index].machine, externalVariables: job.tokens[executing][job.index].externalVariables)
            jobs.append(Job(index: job.index + 1, tokens: newTokens, externals: newExternals, lastState: generatedStates.last, clock: 0))
        }
        return states
    }
    
    fileprivate func convert(_ props: KripkeStatePropertyList) -> [String: Any] {
        var dict: [String: Any] = [:]
        props.properties.forEach {
            dict[$0] = self.convert($1)
        }
        return dict
    }
    
    fileprivate func convert(_ property: KripkeStateProperty) -> Any {
        switch property.type {
        case .EmptyCollection:
            return []
        case .Collection(let arr):
            return arr.map { self.convert($0) }
        case .Compound(let props):
            return self.convert(props)
        default:
            return property.value
        }
    }
    
    fileprivate func out(_ plist: KripkeStatePropertyList, _ level: Int = 0) -> String? {
        func propOut(_ key: String, _ prop: KripkeStateProperty, _ level: Int) -> String? {
            let indent = Array(repeating: " ", count: level * 2).combine("", +)
            switch prop.type {
            case .EmptyCollection:
                return indent + key + ": []"
            case .Collection(let collection):
                let props = collection.enumerated().compactMap { propOut("\($0)", $1, level + 1) }.combine("") { $0 + ",\n" + $1 }
                if props.isEmpty {
                    return nil
                }
                return indent + key + ": [\n" + props  + "\n" + indent + "]"
            case .Compound(let newPlist):
                guard let list = out(newPlist, level + 1) else {
                    return nil
                }
                return indent + key + ": [\n" + list + "\n" + indent + "]"
            default:
                return indent + key + ": " + "\(prop.value)"
            }
        }
        let list = plist.properties.sorted { $0.key < $1.key }.compactMap {
            return propOut($0, $1, level + 1)
            }.combine("") {$0 + ",\n" + $1 }
        return list.isEmpty ? nil : list
    }

}

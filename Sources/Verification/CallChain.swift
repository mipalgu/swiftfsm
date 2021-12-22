/*
 * CallChain.swift
 * Verification
 *
 * Created by Callum McColl on 7/6/21.
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

public struct CallChain: Hashable {
    
    private struct CallID: Hashable {
        
        var callee: FSM_ID
        
        var parameters: [String: Any?]
        
        static func ==(lhs: CallID, rhs: CallID) -> Bool {
            guard lhs.callee == rhs.callee, lhs.parameters.keys == rhs.parameters.keys else {
                return false
            }
            for key in lhs.parameters.keys {
                if KripkeStatePropertyList(lhs.parameters[key]) != KripkeStatePropertyList(rhs.parameters[key]) {
                    return false
                }
            }
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.callee)
            hasher.combine(KripkeStatePropertyList(self.parameters.sorted { $0.key < $1.key }))
        }
        
    }
    
    var root: String
    
    private var indexes: [CallID: Int] = [:]
    
    private(set) var calls: [Call]
    
    var fsm: String {
        calls.last?.fsm ?? root
    }
    
    private init(root: String, indexes: [CallID: Int], calls: [Call]) {
        self.root = root
        self.indexes = indexes
        self.calls = calls
    }
    
    init(root: String, calls: [Call]) {
        let indexes = Dictionary(uniqueKeysWithValues: calls.enumerated().map {
            (CallID(callee: $1.callee, parameters: $1.parameters), $0)
        })
        self.init(root: root, indexes: indexes, calls: calls)
    }
    
    mutating func add(_ call: Call) {
        let id = CallID(callee: call.callee, parameters: call.parameters)
        if let index = indexes[id] {
            fatalError("Cyclic call detected: \(calls[index..<calls.count])")
        }
        indexes[id] = calls.count
        calls.append(call)
    }
    
    func fsm(fromPool pool: FSMPool) -> FSMType {
        guard let last = calls.last else {
            return pool.fsm(root)
        }
        return pool.fsm(last.fsm)
    }
    
}

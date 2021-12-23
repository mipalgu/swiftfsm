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

public struct FSMPool {
    
    private(set) var fsms: [FSMType]
    
    private var indexes: [String: FSM_ID]
    
    var cloned: FSMPool {
        FSMPool(fsms: fsms.map { $0.clone() }, indexes: indexes)
    }
    
    private init(fsms: [FSMType], indexes: [String: FSM_ID]) {
        self.fsms = fsms
        self.indexes = indexes
    }
    
    init(fsms: [FSMType]) {
        self.init(fsms: fsms, indexes: Dictionary(uniqueKeysWithValues: fsms.enumerated().map { ($1.name, $0) }))
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
    
    func index(of name: String) -> FSM_ID {
        guard let index = indexes[name] else {
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
    
    func propertyList(forStep step: VerificationStep, executingState state: String?, collapseIfPossible collapse: Bool = false) -> KripkeStatePropertyList {
        let fsmValues = Dictionary(uniqueKeysWithValues: fsms.map {
            ($0.name, $0.asScheduleableFiniteStateMachine.base)
        })
        let fsmProperties = KripkeStatePropertyList(fsmValues.mapValues {
            KripkeStateProperty(type: .Compound(KripkeStatePropertyList($0)), value: $0)
        })
        return KripkeStatePropertyList(
            [
                "fsms": KripkeStateProperty(type: .Compound(fsmProperties), value: fsmValues),
                "pc": step.property(state: state, collapseIfPossible: collapse)
            ]
        )
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
        "\(fsms.sorted { $0.name < $1.name }.map(\.asScheduleableFiniteStateMachine.base))"
    }
    
}

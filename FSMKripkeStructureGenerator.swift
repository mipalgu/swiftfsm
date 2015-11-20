/*
 * FSMKripkeStructureGenerator.swift
 * swiftfsm
 *
 * Created by Callum McColl on 11/11/2015.
 * Copyright © 2015 Callum McColl. All rights reserved.
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

public struct FSMKripkeStructureGenerator: KripkeStructureGenerator {
    
    private let fsm: FiniteStateMachine
    
    public init(fsm: FiniteStateMachine) {
        self.fsm = fsm
    }
    
    public func generate() -> KripkeStructureType {
        return KripkeStructure(
            initialState: self.generateFromState(
                self.fsm.initialState,
                ringlet: self.fsm.ringlet
            ),
            fsm: self.fsm
        )
    }
    
    private func generateFromState(
        state: State,
        ringlet: Ringlet
    ) -> KripkeState {
        return KripkeState(properties: [
            "Bool": convertValue(true),
            "Int": convertValue(Int(0)),
            "Int8": convertValue(Int8(0)),
            "Int16": convertValue(Int16(0)),
            "Int32": convertValue(Int32(0)),
            "Int64": convertValue(Int64(0)),
            "UInt": convertValue(UInt(0)),
            "UInt8": convertValue(UInt8(0)),
            "UInt16": convertValue(UInt16(0)),
            "UInt32": convertValue(UInt32(0)),
            "UInt64": convertValue(UInt64(0)),
            "Float": convertValue(Float(0)),
            "Float80": convertValue(Float80(0)),
            "Double": convertValue(Double(0)),
            "String": convertValue("str"),
            "Some": convertValue(EmptyState(name: "state"))
        ])
    }
    
    private func convertValue(value: Any) -> KripkeStateProperty {
        let type: KripkeStatePropertyTypes = self.getKripkeStatePropertyType(
            value
        )
        return KripkeStateProperty(type: type, value: value)
    }
    
    private func getKripkeStatePropertyType(
        value: Any
    ) -> KripkeStatePropertyTypes {
        var type: String = ""
        print(value.dynamicType, terminator: "", toStream: &type)
        print(type)
        switch (type) {
        case "Bool":
            return .Bool
        case "Int":
            return .Int
        case "Int8":
            return .Int8
        case "Int16":
            return .Int16
        case "Int32":
            return .Int32
        case "Int64":
            return .Int64
        case "UInt":
            return .UInt
        case "UInt8":
            return .UInt8
        case "UInt16":
            return .UInt16
        case "UInt32":
            return .UInt32
        case "UInt64":
            return .UInt64
        case "Float":
            return .Float
        case "FLoat80":
            return .Float80
        case "Double":
            return .Double
        case "String":
            return .String
        default:
            return .Some
        }
    }
    
}

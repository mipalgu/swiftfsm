/*
 * Call.swift
 * Verification
 *
 * Created by Callum McColl on 14/1/21.
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
import Gateways

struct Call {

    fileprivate struct Parameters: Hashable {

        var parameters: [String: Any?]

        static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
            return KripkeStatePropertyList(lhs) == KripkeStatePropertyList(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(KripkeStatePropertyList(self))
        }

    }
    
    enum Method: String, Codable, CaseIterable, Hashable {
        
        case synchronous
        
        case asynchronous
        
    }

    var caller: (id: FSM_ID, name: String)
    
    var callee: (id: FSM_ID, name: String)
    
    var parameters: [String: Any?]
    
    var method: Method

    var promiseData: PromiseData
    
}

extension Call: Equatable {
    
    static func ==(lhs: Call, rhs: Call) -> Bool {
        guard lhs.caller.0 == rhs.caller.0, lhs.caller.1 == rhs.caller.1, lhs.callee.0 == rhs.callee.0, lhs.callee.1 == rhs.callee.1, lhs.parameters.keys == rhs.parameters.keys, lhs.method == rhs.method else {
            return false
        }
        for key in lhs.parameters.keys {
            if KripkeStatePropertyList(lhs.parameters[key]) != KripkeStatePropertyList(rhs.parameters[key]) {
                return false
            }
        }
        return true
    }
    
}

extension Call: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.caller.0)
        hasher.combine(self.caller.1)
        hasher.combine(self.callee.0)
        hasher.combine(self.callee.1)
        hasher.combine(Parameters(parameters: parameters))
        hasher.combine(self.method)
    }
    
}

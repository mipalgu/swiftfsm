/*
 * KripkeState.swift
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

public class KripkeState: KripkeStateType {
    
    public let fsm: FiniteStateMachine

    public let fsmProperties: [String: KripkeStateProperty]

    public let globalProperties: [String: KripkeStateProperty]

    public let machine: Machine

    public let properties: [String: KripkeStateProperty]
    
    public let state: State
    
    public var target: KripkeState?
    
    public init(
        state: State,
        properties: [String: KripkeStateProperty],
        fsm: FiniteStateMachine,
        machine: Machine,
        fsmProperties: [String: KripkeStateProperty],
        globalProperties: [String: KripkeStateProperty],
        target: KripkeState? = nil
    ) {
        self.state = state
        self.properties = properties
        self.fsm = fsm
        self.machine = machine
        self.fsmProperties = fsmProperties
        self.globalProperties = globalProperties
        self.target = target
    }
    
    public func equals(other: KripkeState) -> Bool {
        // Check if the fsms are the same
        if (self.fsm != other.fsm) {
            return false
        }
        // Check if the states are the same.
        if (self.state != other.state) {
            return false
        }
        // Check if fsm properties are the same
        if (false == self.checkProperties(self.fsmProperties, rhs: other.fsmProperties)) {
            return false
        }
        // Check if the property counts are the same.
        return self.checkProperties(self.properties, rhs: other.properties)
    }

    private func checkProperties(
        lhs: [String: KripkeStateProperty],
        rhs: [String: KripkeStateProperty]
    ) -> Bool {
        // Check if they are the same size
        if (lhs.count != rhs.count) {
            return false
        }
        // Check values
        for key: String in lhs.keys {
            if (nil == rhs[key]) {
                return false
            }
            if (false == (lhs[key]! == rhs[key]!)) {
                return false
            }
        }
        return true
    }
    
}

public func ==(lhs: KripkeState, rhs: KripkeState) -> Bool {
    return lhs.equals(rhs)
}

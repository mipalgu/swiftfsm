/*
 * ModifiableFSMGateway.swift
 * Gateways
 *
 * Created by Callum McColl on 25/12/18.
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
import swiftfsm

public protocol ModifiableFSMGateway: FSMGateway {
    
    var latestID: FSM_ID { get set }
    
    var fsms: [FSM_ID: FSMType] { get set }
    
    var ids: [String: FSM_ID] { get set }
    
}

extension ModifiableFSMGateway {
    
    public func fsm(fromID id: FSM_ID) -> AnyControllableFiniteStateMachine {
        dprint("fetch fsm from id \(id)")
        guard let fsm = self.fsms[id] else {
            fatalError("FSM with id '\(id)' does not exist.")
        }
        guard let controllableFSM = fsm.asControllableFiniteStateMachine else {
            fatalError("Unable to fetch FSM with id '\(id)' as it is not a controllable FSM.")
        }
        return controllableFSM
    }
    
    public func id(of name: String) -> FSM_ID {
        guard let id = self.ids[name] else {
            let id = self.latestID
            self.ids[name] = id
            self.latestID = self.latestID.advanced(by: 1)
            dprint("fetch id \(id) of \(name)")
            return id
        }
        dprint("id \(id) of \(name)")
        return id
    }
    
    public func invokeSelf<R>(_ name: String, withParameters parameters: [String: Any]) -> Promise<R> {
        return self.invokeSelf(self.id(of: name), withParameters: parameters)
    }
    
    public func invoke<R>(_ name: String, withParameters parameters: [String: Any]) -> Promise<R> {
        return self.invoke(self.id(of: name), withParameters: parameters)
    }
    
}

/*
 * RestrictiveFSMGateway.swift 
 * Gateways 
 *
 * Created by Callum McColl on 25/12/2018.
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
import Utilities

public final class RestrictiveFSMGateway<Gateway: FSMGateway, _Formatter: Formatter>: FSMGateway {
    
    fileprivate let gateway: Gateway
    
    fileprivate let selfID: FSM_ID
    
    fileprivate let whitelist: Set<FSM_ID>
    
    fileprivate let callables: Set<FSM_ID>
    
    fileprivate let invocables: Set<FSM_ID>
    
    fileprivate let formatter: _Formatter
    
    public init(
        gateway: Gateway,
        selfID: FSM_ID,
        callables: Set<FSM_ID>,
        invocables: Set<FSM_ID>,
        whitelist: Set<FSM_ID>,
        formatter: _Formatter
    ) {
        self.gateway = gateway
        self.selfID = selfID
        self.callables = callables
        self.invocables = invocables
        self.whitelist = whitelist
        self.formatter = formatter
    }
    
    public func call<R>(_ id: FSM_ID, withParameters parameters: [String : Any], caller: FSM_ID) -> Promise<R> {
        guard
            caller == self.selfID,
            true == self.callables.contains(id)
        else {
            fatalError("Unable to call fsm with id \(id) with caller \(caller)")
        }
        return self.gateway.call(id, withParameters: parameters, caller: caller)
    }
    
    public func callSelf<R>(_ id: FSM_ID, withParameters parameters: [String: Any]) -> Promise<R> {
        guard id == self.selfID else {
            fatalError("Unable to invoke fsm with id \(id)")
        }
        return self.gateway.callSelf(id, withParameters: parameters)
    }
    
    public func invoke<R>(_ id: FSM_ID, withParameters parameters: [String: Any], caller: FSM_ID) -> Promise<R> {
        guard true == self.invocables.contains(id) else {
            fatalError("Unable to invoke fsm with id \(id)")
        }
        return self.gateway.invoke(id, withParameters: parameters, caller: caller)
    }
    
    public func fsm(fromID id: FSM_ID) -> AnyControllableFiniteStateMachine {
        guard true == self.whitelist.contains(id) else {
            fatalError("Unable to fetch fsm with id \(id)")
        }
        return self.gateway.fsm(fromID: id)
    }
    
    public func id(of name: String) -> FSM_ID {
        let name = self.formatter.format(name)
        let id = self.gateway.id(of: name)
        guard true == self.whitelist.contains(id) else {
            fatalError("Unable to fetch id of fsm named \(name)")
        }
        return id
    }
    
}

extension RestrictiveFSMGateway where _Formatter == NullFormatter {
    
    public convenience init(
        gateway: Gateway,
        selfID: FSM_ID,
        callables: Set<FSM_ID>,
        invocables: Set<FSM_ID>,
        whitelist: Set<FSM_ID>
    ) {
        self.init(
            gateway: gateway,
            selfID: selfID,
            callables: callables,
            invocables: invocables,
            whitelist: whitelist,
            formatter: NullFormatter()
        )
    }
    
}

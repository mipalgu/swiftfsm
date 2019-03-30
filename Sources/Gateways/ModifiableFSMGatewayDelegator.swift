/*
 * ModifiableFSMGatewayDelegator.swift
 * Gateways
 *
 * Created by Callum McColl on 5/1/19.
 * Copyright © 2019 Callum McColl. All rights reserved.
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

public protocol ModifiableFSMGatewayDelegator: ModifiableFSMGateway {
    
    associatedtype Gateway: ModifiableFSMGateway
    
    var gateway: Gateway { get set }
    
}

extension ModifiableFSMGateway where Self: ModifiableFSMGatewayDelegator {
    
    public var delegate: FSMGatewayDelegate? {
        get {
            return self.gateway.delegate
        } set {
            self.gateway.delegate = newValue
        }
    }
    
    public var latestID: FSM_ID {
        get {
            return self.gateway.latestID
        } set {
            self.gateway.latestID = newValue
        }
    }
    
    public var fsms: [FSM_ID: FSMType] {
        get {
            return self.gateway.fsms
        } set {
            self.gateway.fsms = newValue
        }
    }
    
    public var ids: [String: FSM_ID] {
        get {
            return self.gateway.ids
        } set {
            self.gateway.ids = newValue
        }
    }
    
    public func id(of name: String) -> FSM_ID {
        return self.gateway.id(of: name)
    }
    
    public func fsm(fromID id: FSM_ID) -> AnyControllableFiniteStateMachine {
        return self.gateway.fsm(fromID: id)
    }
    
    public func call<R>(_ id: FSM_ID, withParameters parameters: [String : Any], caller: FSM_ID) -> Promise<R> {
        return self.gateway.call(id, withParameters: parameters, caller: caller)
    }
    
    public func callSelf<R>(_ id: FSM_ID, withParameters parameters: [String : Any]) -> Promise<R> {
        return self.gateway.callSelf(id, withParameters: parameters)
    }
    
    public func invoke<R>(_ id: FSM_ID, withParameters parameters: [String : Any], caller: FSM_ID) -> Promise<R> {
        return self.gateway.invoke(id, withParameters: parameters, caller: caller)
    }
    
    public func finish(_ id: FSM_ID) {
        self.gateway.finish(id)
    }
    
    public func setup(_ id: FSM_ID) {
        self.gateway.setup(id)
    }
    
}

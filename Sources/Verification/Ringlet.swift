/*
 * Ringlet.swift
 * ArgumentParser
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

import KripkeStructure
import Gateways
import Timers
import swiftfsm

/// Represents a single ringlet execution at a specific time for a specific
/// FSM.
///
/// This struct generates a `KripkeStatePropertyList` before and after the
/// ringlet execution. This struct also records and calls that were made to
/// parameterised machines as well as any calls to the fsms clock.
struct Ringlet {
    
    private final class GatewayDelegate: FSMGatewayDelegate {
        
        var invocations: [Call] = []
        
        var calls: [Call] = []
        
        func hasCalled(inGateway _: ModifiableFSMGateway, fsm _: AnyParameterisedFiniteStateMachine, withId callee: FSM_ID, withParameters parameters: [String: Any?], caller: FSM_ID, storingResultsIn _: PromiseData) {
            self.calls.append(Call(caller: caller, callee: callee, parameters: parameters))
        }

        func hasInvoked(inGateway _: ModifiableFSMGateway, fsm _: AnyParameterisedFiniteStateMachine, withId callee: FSM_ID, withParameters parameters: [String: Any?], caller: FSM_ID, storingResultsIn _: PromiseData) {
            self.invocations.append(Call(caller: caller, callee: callee, parameters: parameters))
        }
        
    }
    
    /// The evaluation of all the variables within the FSM before the
    /// ringlet has executed.
    var preSnapshot: KripkeStatePropertyList
    
    /// The evaluation of all the variables within the FSM after the ringlet has
    /// finished executing.
    var postSnapshot: KripkeStatePropertyList
    
    /// A list of calls made to parameterised machines during the execution of
    /// the ringlet.
    var calls: [Call]
    
    /// A list of clock values which were queried during the execution of the
    /// ringlet.
    var afterCalls: Set<UInt>
    
    /// Create a `Ringlet`.
    ///
    /// Executes the ringlet of the fsm by calling `next`. Uses introspection
    /// to query the variables to create the `Ringlet` structure.
    ///
    /// - Parameter fsm The fsm being inspected to create this ringlet.
    ///
    /// - Parameter gateway The `ModifiableFSMGateway` responsible for handling
    /// parameterised machine invocations. A delegate is created and used to
    /// detect when the fsm makes any calls to other machines.
    init<Gateway: ModifiableFSMGateway, Timer: Clock>(fsm: AnyScheduleableFiniteStateMachine, gateway: Gateway, timer: Timer) {
        let preSnapshot = KripkeStatePropertyList(fsm.base)
        let delegate = GatewayDelegate()
        gateway.delegate = delegate
        fsm.next()
        let postSnapshot = KripkeStatePropertyList(fsm.base)
        let calls = delegate.invocations + delegate.calls
        self.init(preSnapshot: preSnapshot, postSnapshot: postSnapshot, calls: calls, afterCalls: Set(timer.lastClockValues))
    }
    
    /// Create a `Ringlet`.
    init(preSnapshot: KripkeStatePropertyList, postSnapshot: KripkeStatePropertyList, calls: [Call], afterCalls: Set<UInt>) {
        self.preSnapshot = preSnapshot
        self.postSnapshot = postSnapshot
        self.calls = calls
        self.afterCalls = afterCalls
    }
    
}

extension Ringlet: Equatable {}

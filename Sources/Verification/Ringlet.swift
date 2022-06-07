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

        let callerName: String

        init(callerName: String) {
            self.callerName = callerName
        }
        
        func hasCalled(inGateway _: ModifiableFSMGateway, fsm: AnyParameterisedFiniteStateMachine, withId callee: FSM_ID, withParameters parameters: [String: Any?], caller: FSM_ID, storingResultsIn promiseData: PromiseData) {
            self.calls.append(Call(caller: (caller, callerName), callee: (callee, fsm.name), parameters: parameters, method: .synchronous, promiseData: promiseData))
        }

        func hasInvoked(inGateway _: ModifiableFSMGateway, fsm: AnyParameterisedFiniteStateMachine, withId callee: FSM_ID, withParameters parameters: [String: Any?], caller: FSM_ID, storingResultsIn promiseData: PromiseData) {
            self.invocations.append(Call(caller: (caller, callerName), callee: (callee, fsm.name), parameters: parameters, method: .asynchronous, promiseData: promiseData))
        }
        
    }
    
    /// The fsm before executing the ringlet.
    var fsmBefore: FSMType
    
    /// The fsm after executing the ringlet
    var fsmAfter: FSMType
    
    /// The timeslot where the fsm was executed.
    var timeslot: Timeslot
    
    /// The state of all fsms before this ringlet executed.
    var before: FSMPool
    
    /// The state of all fsms after this ringlet executed.
    var after: FSMPool
    
    /// Did the fsm transition during the ringlet execution?
    var transitioned: Bool
    
    /// The evaluation of all external variables of the FSM before the ringlet
    /// was executed.
    var externalsPreSnapshot: KripkeStatePropertyList
    
    /// The evaluation of all external variables of the FSM after the ringlet
    /// was executed.
    var externalsPostSnapshot: KripkeStatePropertyList
    
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
    init<Gateway: ModifiableFSMGateway, Timer: Clock>(fsm: FSMType, timeslot: Timeslot, gateway: Gateway, timer: Timer) where Gateway: NewVerifiableGateway {
        let allExternalVariables = (fsm.sensors + fsm.externalVariables + fsm.actuators)
        let externalsPreSnapshot = KripkeStatePropertyList(Dictionary(uniqueKeysWithValues: allExternalVariables.map { ($0.name, KripkeStateProperty($0.val)) }))
        let preSnapshot = KripkeStatePropertyList(fsm.asScheduleableFiniteStateMachine.base)
        let delegate = GatewayDelegate(callerName: fsm.name)
        gateway.delegate = delegate
        let before = gateway.pool
        let currentState = fsm.currentState.name
        var clone = fsm.clone()
        gateway.replace(clone)
        clone.next()
        let after = gateway.pool
        let transitioned = currentState != clone.currentState.name
        let externalsPostSnapshot = KripkeStatePropertyList(Dictionary(uniqueKeysWithValues: allExternalVariables.map { ($0.name, KripkeStateProperty($0.val)) }))
        let postSnapshot = KripkeStatePropertyList(clone.asScheduleableFiniteStateMachine.base)
        let calls = delegate.invocations + delegate.calls
        self.init(
            fsmBefore: fsm,
            fsmAfter: clone,
            timeslot: timeslot,
            before: before,
            after: after,
            transitioned: transitioned,
            externalsPreSnapshot: externalsPreSnapshot,
            externalsPostSnapshot: externalsPostSnapshot,
            preSnapshot: preSnapshot,
            postSnapshot: postSnapshot,
            calls: calls,
            afterCalls: Set(timer.lastClockValues)
        )
    }
    
    /// Create a `Ringlet`.
    init(fsmBefore: FSMType, fsmAfter: FSMType, timeslot: Timeslot, before: FSMPool, after: FSMPool, transitioned: Bool, externalsPreSnapshot: KripkeStatePropertyList, externalsPostSnapshot: KripkeStatePropertyList, preSnapshot: KripkeStatePropertyList, postSnapshot: KripkeStatePropertyList, calls: [Call], afterCalls: Set<UInt>) {
        self.fsmBefore = fsmBefore
        self.fsmAfter = fsmAfter
        self.timeslot = timeslot
        self.before = before
        self.after = after
        self.transitioned = transitioned
        self.externalsPreSnapshot = externalsPreSnapshot
        self.externalsPostSnapshot = externalsPostSnapshot
        self.preSnapshot = preSnapshot
        self.postSnapshot = postSnapshot
        self.calls = calls
        self.afterCalls = afterCalls
    }
    
}

extension Ringlet: Hashable {
    
    static func ==(lhs: Ringlet, rhs: Ringlet) -> Bool {
        lhs.transitioned == rhs.transitioned
        && lhs.externalsPreSnapshot == rhs.externalsPreSnapshot
        && lhs.externalsPostSnapshot == rhs.externalsPostSnapshot
        && lhs.preSnapshot == rhs.preSnapshot
        && lhs.postSnapshot == rhs.postSnapshot
        && lhs.calls == rhs.calls
        && lhs.afterCalls == rhs.afterCalls
        && lhs.timeslot == rhs.timeslot
        && KripkeStatePropertyList(lhs.fsmBefore.asScheduleableFiniteStateMachine.base) == KripkeStatePropertyList(rhs.fsmBefore.asScheduleableFiniteStateMachine.base)
        && KripkeStatePropertyList(lhs.fsmAfter.asScheduleableFiniteStateMachine.base) == KripkeStatePropertyList(rhs.fsmAfter.asScheduleableFiniteStateMachine.base)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(transitioned)
        hasher.combine(externalsPreSnapshot)
        hasher.combine(externalsPostSnapshot)
        hasher.combine(preSnapshot)
        hasher.combine(postSnapshot)
        hasher.combine(calls)
        hasher.combine(afterCalls)
        hasher.combine(timeslot)
        hasher.combine(KripkeStatePropertyList(fsmBefore.asScheduleableFiniteStateMachine.base))
        hasher.combine(KripkeStatePropertyList(fsmAfter.asScheduleableFiniteStateMachine.base))
    }
    
}

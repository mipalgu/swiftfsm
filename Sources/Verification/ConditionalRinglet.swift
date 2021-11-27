/*
 * ConditionalRinglet.swift
 * Verification
 *
 * Created by Callum McColl on 16/2/21.
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
import swiftfsm

struct ConditionalRinglet {
    
    /// The fsm that was executed.
    var fsm: FSMType
    
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

    /// The condition on the clock when this ringlet is able to execute.
    var condition: Constraint<UInt>
    
    init(ringlet: Ringlet, condition: Constraint<UInt>) {
        self.init(fsm: ringlet.fsm, before: ringlet.before, after: ringlet.after, transitioned: ringlet.transitioned, externalsPreSnapshot: ringlet.externalsPreSnapshot, externalsPostSnapshot: ringlet.externalsPostSnapshot, preSnapshot: ringlet.preSnapshot, postSnapshot: ringlet.postSnapshot, calls: ringlet.calls, condition: condition)
    }
    
    /// Create a `ConditionalRinglet`.
    init(fsm: FSMType, before: FSMPool, after: FSMPool, transitioned: Bool, externalsPreSnapshot: KripkeStatePropertyList, externalsPostSnapshot: KripkeStatePropertyList, preSnapshot: KripkeStatePropertyList, postSnapshot: KripkeStatePropertyList, calls: [Call], condition: Constraint<UInt>) {
        self.fsm = fsm
        self.before = before
        self.after = after
        self.transitioned = transitioned
        self.externalsPreSnapshot = externalsPreSnapshot
        self.externalsPostSnapshot = externalsPostSnapshot
        self.preSnapshot = preSnapshot
        self.postSnapshot = postSnapshot
        self.calls = calls
        self.condition = condition
    }
    
}

extension ConditionalRinglet: Hashable {
    
    static func ==(lhs: ConditionalRinglet, rhs: ConditionalRinglet) -> Bool {
        lhs.transitioned == rhs.transitioned
        && lhs.externalsPreSnapshot == rhs.externalsPreSnapshot
        && lhs.externalsPostSnapshot == rhs.externalsPostSnapshot
        && lhs.preSnapshot == rhs.preSnapshot
        && lhs.postSnapshot == rhs.postSnapshot
        && lhs.calls == rhs.calls
        && lhs.condition == rhs.condition
        && KripkeStatePropertyList(lhs.fsm.asScheduleableFiniteStateMachine.base) == KripkeStatePropertyList(rhs.fsm.asScheduleableFiniteStateMachine.base)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(transitioned)
        hasher.combine(externalsPreSnapshot)
        hasher.combine(externalsPostSnapshot)
        hasher.combine(preSnapshot)
        hasher.combine(postSnapshot)
        hasher.combine(calls)
        hasher.combine(condition)
        hasher.combine(KripkeStatePropertyList(fsm.asScheduleableFiniteStateMachine.base))
    }
    
}

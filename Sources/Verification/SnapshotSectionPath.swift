/*
 * SnapshotSectionPath.swift
 * Verification
 *
 * Created by Callum McColl on 2/6/21.
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

/// Represents a particular execution of ringlets within the schedule between
/// taking a snapshot of the external variables and saving the snapshot of
/// external variables.
struct SnapshotSectionPath: Hashable {
    
    struct State: Hashable {
        
        /// The ringlets of the fsms that were executed previously in this snapshot
        /// phase.
        var previous: [CallAwareRinglet]
        
        /// The ringlet of the last fsm to be executed in this snapshot phase.
        var current: CallAwareRinglet
        
        /// The state of all fsms before this ringlet was executed.
        var before: FSMPool {
            get {
                current.ringlet.before
            } set {
                current.ringlet.before = newValue
            }
        }
        
        /// The state of all fsms after this ringlet was executed.
        var after: FSMPool {
            get {
                current.ringlet.after
            } set {
                current.ringlet.after = newValue
            }
        }
        
        /// The fsm that was executed.
        var fsm: FSMType
        
        /// The number of consecutive ringlets that have been executed without
        /// the fsm transitioning.
        var cyclesExecuted: UInt
        
        /// A convenience getter that returns `previous` and `current` in a
        /// single array.
        var toCurrent: [CallAwareRinglet] {
            previous + [current]
        }
        
        static func ==(lhs: State, rhs: State) -> Bool {
            return lhs.previous == rhs.previous
            && lhs.current == rhs.current
            && lhs.cyclesExecuted == rhs.cyclesExecuted
            && KripkeStatePropertyList(lhs.fsm.asScheduleableFiniteStateMachine.base) == KripkeStatePropertyList(rhs.fsm.asScheduleableFiniteStateMachine.base)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(previous)
            hasher.combine(current)
            hasher.combine(KripkeStatePropertyList(fsm.asScheduleableFiniteStateMachine.base))
            hasher.combine(cyclesExecuted)
        }
        
    }
    
    /// The ringlets that were executed within an external variable snapshot
    /// phase.
    var ringlets: [State]
    
    var before: FSMPool {
        get {
            ringlets.first!.before
        } set {
            ringlets[0].before = newValue
        }
    }
    
    var after: FSMPool {
        get {
            ringlets.last!.after
        } set {
            ringlets[ringlets.count - 1].after = newValue
        }
    }
    
}

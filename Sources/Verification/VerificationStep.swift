/*
 * VerificationStep.swift
 * Verification
 *
 * Created by Callum McColl on 21/12/21.
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

enum VerificationStep: Hashable {

    case startDelegates(fsms: Set<Timeslot>)

    case endDelegates(fsms: Set<Timeslot>)
    
    case takeSnapshot(fsms: Set<Timeslot>)
    
    case takeSnapshotAndStartTimeslot(timeslot: Timeslot)
    
    case startTimeslot(timeslot: Timeslot)
    
    case execute(timeslot: Timeslot)
    
    case executeAndSaveSnapshot(timeslot: Timeslot)
    
    case saveSnapshot(fsms: Set<Timeslot>)
    
    var takeSnapshot: Bool {
        switch self {
        case .takeSnapshot, .takeSnapshotAndStartTimeslot:
            return true
        default:
            return false
        }
    }
    
    var startTimeslot: Bool {
        switch self {
        case .startTimeslot, .takeSnapshotAndStartTimeslot:
            return true
        default:
            return false
        }
    }
    
    var saveSnapshot: Bool {
        switch self {
        case .saveSnapshot, .executeAndSaveSnapshot:
            return true
        default:
            return false
        }
    }
    
    var marker: String {
        switch self {
        case .takeSnapshot, .takeSnapshotAndStartTimeslot:
            return "R"
        case .startTimeslot, .startDelegates:
            return "S"
        case .execute, .endDelegates:
            return "E"
        case .executeAndSaveSnapshot, .saveSnapshot:
            return "W"
        }
    }
    
    var timeslots: Set<Timeslot> {
        switch self {
        case .takeSnapshot(let fsms), .saveSnapshot(let fsms), .startDelegates(let fsms), .endDelegates(let fsms):
            return fsms
        case .takeSnapshotAndStartTimeslot(let timeslot), .startTimeslot(let timeslot), .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
            return [timeslot]
        }
    }
    
    var fsms: Set<String> {
        Set(timeslots.map(\.callChain.fsm))
    }
    
    func property(state: String?, collapseIfPossible: Bool = false) -> KripkeStateProperty {
        let fsms = self.fsms
        if let first = fsms.first, fsms.count == 1 && collapseIfPossible {
            return KripkeStateProperty(type: .String, value: first + "." + (state.map { $0 + "." } ?? "") + marker)
        } else {
            let marker = self.marker
            let names = fsms.sorted()
            var value: [String: Any] = [
                "step": marker,
                "fsms": names
            ]
            var plist: [String: KripkeStateProperty] = [
                "step": KripkeStateProperty(marker),
                "fsms": KripkeStateProperty(type: .Collection(names.map { KripkeStateProperty($0) }), value: names)
            ]
            if let state = state {
                value["state"] = state
                plist["state"] = KripkeStateProperty(type: .String, value: state)
            }
            return KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(properties: plist)),
                value: value
            )
        }
    }
    
}

/*
 * VerificationMap.swift
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

import swift_helpers

struct VerificationMap {
    
    struct Step: Hashable {
        
        var time: UInt
        
        var step: VerificationStep
        
    }
    
    private(set) var steps: SortedCollection<Step>

    var delegates: Set<String>
    
    init(steps: [Step], delegates: Set<String>) {
        self.steps = SortedCollection(unsortedSequence: steps) {
            if $0.time == $1.time {
                return .orderedSame
            } else if $0.time < $1.time {
                return .orderedAscending
            } else {
                return .orderedDescending
            }
        }
        self.delegates = delegates
    }

    mutating func handleFinishedCall(_ call: Call) {
        replaceSteps {
            guard $0.callChain.fsm == call.callee.name else {
                return $0
            }
            var new = $0
            new.callChain.pop()
            return new
        }
    }

    mutating func handleCall(_ call: Call) {
        switch call.method {
        case .synchronous:
            handleSyncCall(call)
        case .asynchronous:
            handleASyncCall(call)
        }
    }

    private mutating func handleSyncCall(_ call: Call) {
        replaceSteps {
            guard $0.callChain.fsm == call.caller.name else {
                return $0
            }
            var new = $0
            new.callChain.add(call)
            return new
        }
    }

    private mutating func handleASyncCall(_ call: Call) {
        replaceSteps {
            guard $0.callChain.root == call.callee.name else {
                return $0
            }
            guard $0.callChain.calls.isEmpty else {
                fatalError("Attempting to call callee that is currently already executing.")
            }
            var new = $0
            new.callChain.add(call)
            return new
        }
    }

    private mutating func replaceSteps(_ transform: (Timeslot) throws -> Timeslot) rethrows {
        var newSteps = Array(steps)
        for (index, step) in steps.enumerated() {
            switch step.step {
            case .takeSnapshot(let timeslots), .saveSnapshot(let timeslots), .startDelegates(let timeslots), .endDelegates(let timeslots):
                let newTimeslots: Set<Timeslot> = try Set(timeslots.map(transform))
                let newStep: VerificationStep
                switch step.step {
                case .takeSnapshot:
                    newStep = .takeSnapshot(fsms: newTimeslots)
                case .saveSnapshot:
                    newStep = .saveSnapshot(fsms: newTimeslots)
                case .startDelegates:
                    newStep = .startDelegates(fsms: newTimeslots)
                case .endDelegates:
                    newStep = .endDelegates(fsms: newTimeslots)
                default:
                    fatalError("Attempting to assign new timeslots to a step that is not supported")
                }
                newSteps[index] = Step(time: step.time, step: newStep)
            case .execute(let timeslot),
                .executeAndSaveSnapshot(let timeslot),
                .startTimeslot(let timeslot),
                .takeSnapshotAndStartTimeslot(let timeslot):
                let new = try transform(timeslot)
                let newStep: VerificationStep
                switch step.step {
                case .execute:
                    newStep = .execute(timeslot: new)
                case .executeAndSaveSnapshot:
                    newStep = .executeAndSaveSnapshot(timeslot: new)
                case .startTimeslot:
                    newStep = .startTimeslot(timeslot: new)
                default:
                    newStep = .takeSnapshotAndStartTimeslot(timeslot: new)
                }
                newSteps[index] = Step(time: step.time, step: newStep)
            }
        }
        self.steps = SortedCollection(sortedArray: newSteps, comparator: self.steps.comparator)
    }

    func hasFinished(forPool pool: FSMPool) -> Bool {
        let fsms: Set<String> = Set(steps.lazy.flatMap { (step: Step) -> Set<String> in
            switch step.step {
            case .startDelegates, .endDelegates:
                return []
            default:
                return step.step.fsms
            }
        })
        return !pool.parameterisedFSMs.values.contains { $0.status == .executing } && !fsms.contains { !pool.fsm($0).hasFinished }
    }
    
}

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
    
    struct Step {
        
        var time: UInt
        
        var step: VerificationStep
        
    }
    
    private var stepLookup: [(ClosedRange<UInt>, Step)]
    
    private(set) var steps: SortedCollection<Step>
    
    init() {
        self.init(steps: [], stepLookup: [])
    }
    
    init(steps: [Step], stepLookup: [(ClosedRange<UInt>, Step)]) {
        let collection = SortedCollection<Step>.init(unsortedSequence: steps) {
            if $0.time < $1.time {
                return .orderedAscending
            }
            if $0.time > $1.time {
                return .orderedDescending
            }
            return .orderedSame
        }
        self.stepLookup = stepLookup
        self.steps = collection
    }
    
    mutating func insert(section: [Timeslot], read: UInt, write: UInt) {
        guard let first = section.first else {
            return
        }
        guard nil == stepLookup.first(where: { ($0.0.lowerBound >= read && $0.0.lowerBound <= write) || ($0.0.upperBound >= read && $0.0.upperBound <= write) }) else {
            fatalError("Attempting to insert a verification step that conflicts with a previous verification step.")
        }
        if section.count == 1, write == first.startingTime + first.duration {
            let firstStep = Step(time: read, step: .takeSnapshotAndStartTimeslot(timeslot: first))
            stepLookup.append((read...write, firstStep))
            steps.insert(firstStep)
            steps.insert(Step(time: write, step: .executeAndSaveSnapshot(timeslot: first)))
            return
        } else {
            let firstStep = Step(time: read, step: .takeSnapshot(fsms: Set(section)))
            stepLookup.append((read...write, firstStep))
            steps.insert(firstStep)
            for timeslot in section {
                let startStep = Step(
                    time: timeslot.startingTime,
                    step: .startTimeslot(timeslot: timeslot)
                )
                steps.insert(startStep)
                let executeStep = Step(
                    time: timeslot.startingTime + timeslot.duration,
                    step: .execute(timeslot: timeslot)
                )
                steps.insert(executeStep)
            }
            let step = Step(time: write, step: .saveSnapshot(fsms: Set(section)))
            steps.insert(step)
        }
    }
    
    mutating func insert(step: VerificationStep, atTime time: ClosedRange<UInt>) {
        let lowerBound = time.lowerBound
        let upperBound = time.upperBound
        guard nil == stepLookup.first(where: { ($0.0.lowerBound >= lowerBound && $0.0.lowerBound <= upperBound) || ($0.0.upperBound >= lowerBound && $0.0.upperBound <= upperBound) }) else {
            fatalError("Attempting to insert a verification step that conflicts with a previous verification step.")
        }
        let step = Step(time: upperBound, step: step)
        stepLookup.append((lowerBound...upperBound, step))
        steps.insert(step)
    }
    
}

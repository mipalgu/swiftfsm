//
/*
 * File.swift
 * 
 *
 * Created by Callum McColl on 11/7/21.
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

/// Represents a single sequential static schedule composed of
/// `SnapshotSection`s.
struct ScheduleThread: Hashable {
    
    /// All `SnapshotSection`s making up the sequential schedule.
    var sections: [SnapshotSection]

    var externalDependencies: Set<ShallowDependency> {
        Set(sections.flatMap(\.externalDependencies))
    }

    var isValid: Bool {
        if nil != sections.first(where: { !$0.isValid }) {
            return false
        }
        let timeslots = sections.flatMap { $0.timeslots }
        for i in 0..<timeslots.count {
            for j in (i + 1)..<timeslots.count {
                if timeslots[i].overlaps(with: timeslots[j]) {
                    return false
                }
            }
        }
        return true
    }

    var verificationMap: VerificationMap {
        let steps = sections.sorted { $0.startingTime < $1.startingTime }.flatMap { (section) -> [VerificationMap.Step] in
            if section.timeslots.count == 1 {
                return [
                    VerificationMap.Step(time: section.startingTime, step: .takeSnapshotAndStartTimeslot(timeslot: section.timeslots[0])),
                    VerificationMap.Step(time: section.startingTime + section.duration, step: .executeAndSaveSnapshot(timeslot: section.timeslots[0]))
                ]
            }
            let startStep = VerificationMap.Step(time: section.startingTime, step: .takeSnapshot(fsms: Set(section.timeslots)))
            let fsmSteps = section.timeslots.flatMap {
                [
                    VerificationMap.Step(time: $0.startingTime, step: .startTimeslot(timeslot: $0)),
                    VerificationMap.Step(time: $0.duration, step: .execute(timeslot: $0))
                ]
            }
            let endStep = VerificationMap.Step(time: section.startingTime, step: .saveSnapshot(fsms: Set(section.timeslots)))
            return [startStep] + fsmSteps + [endStep]
        }
        return VerificationMap(steps: steps, stepLookup: [])
    }

    mutating func add(_ section: SnapshotSection) {
        sections.append(section)
    }

    mutating func merge(_ other: ScheduleThread) {
        for section in other.sections {
            if let sameIndex = self.sections.firstIndex(where: { $0.timeRange == section.timeRange }) {
                self.sections[sameIndex].timeslots.append(contentsOf: section.timeslots)
            } else {
                self.sections.append(section)
            }
        }
        self.sections.sort { $0.startingTime <= $1.startingTime }
    }

    func sharesDependencies(with other: ScheduleThread) -> Bool {
        !externalDependencies.intersection(other.externalDependencies).isEmpty
    }

    func willOverlap(_ section: SnapshotSection) -> Bool {
        nil != sections.first { $0.overlaps(with: section) }
    }

    func willOverlapUnlessSame(_ other: ScheduleThread) -> Bool {
        if self.sections.isEmpty {
            return false
        }
        for i in 0..<(sections.count - 1) {
            if nil != sections[(i + 1)..<sections.count].first(where: {
                $0.overlapsUnlessSame(with: sections[i])
            }) {
                return true
            }
        }
        return false
    }
    
}

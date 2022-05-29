/*
 * Schedule.swift
 * Verification
 *
 * Created by Callum McColl on 28/11/21.
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

struct Schedule: Hashable {

    private struct SequentialSchedule {

        private(set) var sections: [SnapshotSection]

        mutating func add(_ section: SnapshotSection) {
            sections.append(section)
        }

        func willOverlap(_ section: SnapshotSection) -> Bool {
            nil != sections.first { $0.overlaps(with: section) }
        }

    }
    
    var cycleLength: UInt {
        threads.map {
            guard let last = $0.sections.last else {
                fatalError("Schedule must contain at least one section")
            }
            guard let lastTimeslot = last.timeslots.last else {
                fatalError("Schedule snapshot section must contain at least one timeslot")
            }
            return lastTimeslot.startingTime + lastTimeslot.duration
        }.max() ?? 0
    }

    var allTimeslots: [Timeslot] {
        threads.flatMap { $0.sections.flatMap(\.timeslots) }
    }

    var threads: [ScheduleThread]

    func isValid(forPool fsmPool: FSMPool) -> Bool {
        if nil != threads.first(where: { !$0.isValid }) {
            return false
        }
        let sections = threads.flatMap(\.sections)
        var schedules: [String: SequentialSchedule] = [:]
        for section in sections {
            let fsms = Set(section.timeslots.flatMap { $0.fsms }).map { fsmPool.fsm($0) }
            let dependencies = Set(fsms.flatMap { $0.externalVariables.map(\.name) + $0.sensors.map(\.name) + $0.actuators.map(\.name) })
            for dependency in dependencies {
                var schedule = schedules[dependency] ?? SequentialSchedule(sections: [])
                if schedule.willOverlap(section) {
                    return false
                }
                schedule.add(section)
                schedules[dependency] = schedule
            }
        }
        return true
    }
    
}

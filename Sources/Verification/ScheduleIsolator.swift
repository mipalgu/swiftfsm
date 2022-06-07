/*
 * ScheduleIsolator.swift
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

import swiftfsm

/// Is responsible for splitting a schedule into discrete verifiable
/// subcomponents based on the communication lines between fsms.
struct ScheduleIsolator: ScheduleIsolatorProtocol {

    private var parameterisedThreads: [String: IsolatedThread]
    
    var threads: [IsolatedThread]
    
    var cycleLength: UInt
    
    init(schedule: Schedule, allFsms: FSMPool) {
        if !schedule.isValid(forPool: allFsms) {
            fatalError("Cannot partition an invalid schedule.")
        }
        var schedules = schedule.threads.flatMap {
            $0.sections.flatMap { (section) -> [ScheduleThread] in
                section.timeslots.map {
                    ScheduleThread(
                        sections: [
                            SnapshotSection(
                                startingTime: section.startingTime,
                                duration: section.duration,
                                timeslots: [$0]
                            )
                        ]
                    )
                }
            }
        }
        var i = 0
        outerLoop: while i < (schedules.count - 1) {
            for j in (i + 1)..<schedules.count {
                if schedules[i].sharesDependencies(with: schedules[j]) {
                    if schedules[i].willOverlapUnlessSame(schedules[j]) {
                        fatalError("Detected overlapping schedules that should be combined")
                    }
                    schedules[i].merge(schedules[j])
                    schedules.remove(at: j)
                    continue outerLoop
                }
            }
            i += 1
        }
        var parameterisedThreads: [String: IsolatedThread] = [:]
        for i in (schedules.count - 1)...0 {
            let fsms = Set(schedules[i].sections.flatMap(\.timeslots).flatMap(\.fsms))
            if fsms.contains(where: { allFsms.fsm($0).parameters == nil }) {
                continue
            }
            let parameterised = fsms.filter { allFsms.fsm($0).parameters != nil }
            let map = schedules[i].verificationMap(delegates: [])
            parameterised.forEach {
                parameterisedThreads[$0] = IsolatedThread(
                    map: map,
                    pool: FSMPool(fsms: parameterised.map { allFsms.fsm($0).clone() }, parameterisedFSMs: [])
                )
            }
            schedules.remove(at: i)
        }
        let isolatedThreads: [IsolatedThread] = schedules.map {
            let fsms = Set($0.sections.flatMap(\.timeslots).flatMap(\.fsms))
            return IsolatedThread(
                map: $0.verificationMap(delegates: []),
                pool: FSMPool(fsms: fsms.map { allFsms.fsm($0).clone() }, parameterisedFSMs: [])
            )
        }
        self.init(threads: isolatedThreads, parameterisedThreads: parameterisedThreads, cycleLength: schedule.cycleLength)
    }
    
    init(threads: [IsolatedThread], parameterisedThreads: [String: IsolatedThread], cycleLength: UInt) {
        self.threads = threads
        self.parameterisedThreads = parameterisedThreads
        self.cycleLength = cycleLength
    }

    func thread(forFsm fsm: String) -> IsolatedThread? {
        parameterisedThreads[fsm]
    }
    
}

extension Dictionary where Value: RangeReplaceableCollection {
    
    mutating func insert(_ value: Value.Element, into key: Key) {
        if self[key] == nil {
            self[key] = Value([value])
        } else {
            self[key]?.append(value)
        }
    }
    
}

extension Dictionary where Value: SetAlgebra {
    
    mutating func insert(_ value: Value.Element, into key: Key) {
        if self[key] == nil {
            var collection = Value()
            collection.insert(value)
            self[key] = collection
        } else {
            self[key]?.insert(value)
        }
    }
    
}

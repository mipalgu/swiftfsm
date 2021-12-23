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
    
    var threads: [IsolatedThread]
    
    var cycleLength: UInt
    
    init(schedule: Schedule, allFsms: FSMPool) {
        typealias FSM_Name = String
        typealias External_Name = String
        let fsms: [FSM_Name: FSMType] = Dictionary(uniqueKeysWithValues: allFsms.fsms.map { ($0.name, $0) })
        var fsmBins: [Int: Set<FSM_Name>] = [:]
        var bins: [Int: Set<External_Name>] = [:]
        var binIds: [External_Name: Int] = [:]
        var latestId = 0
        for fsm in allFsms.fsms {
            for external in fsm.sensors + fsm.externalVariables + fsm.actuators {
                let id = binIds[external.name] ?? latestId
                if nil == binIds[external.name] {
                    binIds[external.name] = id
                    latestId += 1
                }
                bins.insert(external.name, into: id)
                fsmBins.insert(fsm.name, into: id)
            }
        }
        binsLoop: for i in 0..<latestId {
            guard let bin = bins[i] else {
                continue
            }
            for j in (i + 1)...latestId {
                guard let otherBin = bins[j], otherBin.intersection(bin).isEmpty else {
                    continue
                }
                bins[j] = otherBin.union(bin)
                bins[i] = nil
                fsmBins[j] = (fsmBins[j] ?? Set()).union(fsmBins[i] ?? Set())
                fsmBins[i] = nil
                continue binsLoop
            }
        }
        let groups = Array(fsmBins.values)
        let maps: [(VerificationMap, FSMPool)] = groups.map { group in
            var map = VerificationMap()
            for thread in schedule.threads {
                for section in thread.sections {
                    guard let first = section.timeslots.first, let last = section.timeslots.last else {
                        continue
                    }
                    let validTimeslots = section.timeslots.filter {
                        nil != $0.fsms.first { group.contains($0) }
                    }
                    guard !validTimeslots.isEmpty else {
                        continue
                    }
                    map.insert(section: validTimeslots, read: first.startingTime, write: last.startingTime + last.duration)
                }
            }
            let pool = FSMPool(fsms: allFsms.fsms.filter { group.contains($0.name) })
            return (map, pool)
        }
        self.init(threads: maps.map { IsolatedThread(map: $0, pool: $1) }, cycleLength: schedule.cycleLength)
    }
    
    init(threads: [IsolatedThread], cycleLength: UInt) {
        self.threads = threads
        self.cycleLength = cycleLength
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

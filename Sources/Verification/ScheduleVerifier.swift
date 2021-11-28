/*
 * ScheduleVerifier.swift
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
import Gateways
import Timers
import KripkeStructure
import KripkeStructureViews

struct ScheduleVerifier {
    
    private struct Job {
        
        var initial: Bool {
            previous == nil
        }
        
        var thread: ScheduleThread
        
        var pool: FSMPool
        
        var previous: KripkeState?
        
    }
    
    var schedule: Schedule
    
    var allFsms: FSMPool
    
    init(schedule: Schedule, allFsms: FSMPool) {
        self.schedule = schedule
        self.allFsms = allFsms
    }
    
    func verify<Gateway: ModifiableFSMGateway, Timer: Clock, View: KripkeStructureView, Detector: CycleDetector>(gateway: Gateway, timer: Timer, view: View, cycleDetector: Detector) where Gateway: NewVerifiableGateway, Detector.Element == KripkeStatePropertyList, View.State == KripkeState {
        let isolatedThreads = ScheduleIsolator(schedule: schedule, allFsms: allFsms)
        let cycleLength = schedule.cycleLength
        for thread in isolatedThreads.threads {
            var cycleData = cycleDetector.initialData
            var jobs = [Job(thread: thread.thread, pool: thread.pool, previous: nil)]
            var states: [KripkeStatePropertyList: KripkeState] = [:]
            states.reserveCapacity(1000000)
            while !jobs.isEmpty {
                let job = jobs.removeFirst()
                let variations = ScheduleThreadVariations(
                    pool: job.pool,
                    thread: job.thread,
                    gateway: gateway,
                    timer: timer,
                    cycleLength: cycleLength
                )
                for path in variations.pathways {
                    let previous = job.previous
                    for sectionPath in path.sections {
                        for ringlet in sectionPath.ringlets {
                            let beforeProperties = ringlet.beforeProperties
                            let beforeState = states[beforeProperties] ?? KripkeState(isInitial: previous == nil, properties: beforeProperties)
                            if let previous = previous {
                                previous.addEdge(
                                    KripkeEdge(
                                        clockName: nil,
                                        constraint: nil,
                                        resetClock: false,
                                        target: beforeProperties
                                    )
                                )
                            }
                            let afterProperties = ringlet.afterProperties
                            beforeState.addEdge(
                                KripkeEdge(
                                    clockName: ringlet.fsmBefore.name,
                                    constraint: ringlet.current.ringlet.condition,
                                    resetClock: ringlet.transitioned,
                                    time: ringlet.current.ringlet.timeslot.duration,
                                    target: beforeProperties
                                )
                            )
                            states[beforeProperties] = beforeState
                            let afterState = states[afterProperties] ?? KripkeState(isInitial: false, properties: afterProperties)
                            states[afterProperties] = afterState
                        }
                    }
                    if !cycleDetector.inCycle(data: &cycleData, element: path.afterProperties) {
                        jobs.append(Job(thread: job.thread, pool: path.after))
                    }
                }
            }
        }
    }
    
}

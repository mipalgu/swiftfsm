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

struct ScheduleVerifier<Isolator: ScheduleIsolatorProtocol> {
    
    private struct Previous {
        
        var state: KripkeState
        
        var time: UInt
        
        var resetClocks: Set<String>
        
        func afterExecutingTimeUntil(time: UInt, cycleLength: UInt) -> UInt {
            let currentTime = self.time
            if time >= currentTime {
                return time - currentTime
            } else {
                return (cycleLength - currentTime) + time
            }
        }
        
    }
    
    private struct Job {
        
        var initial: Bool {
            previous == nil
        }
        
        var step: Int
        
        var map: VerificationMap
        
        var pool: FSMPool
        
        var previous: Previous?
        
    }
    
    var isolatedThreads: Isolator
    
    init(schedule: Schedule, allFsms: FSMPool) where Isolator == ScheduleIsolator {
        self.init(isolatedThreads: ScheduleIsolator(schedule: schedule, allFsms: allFsms))
    }
    
    init(isolatedThreads: Isolator) {
        self.isolatedThreads = isolatedThreads
    }
    
    func verify<
        Gateway: ModifiableFSMGateway,
        Timer: Clock,
        ViewFactory: KripkeStructureViewFactory,
        Detector: CycleDetector
    >(
        gateway: Gateway,
        timer: Timer,
        viewFactory: ViewFactory,
        cycleDetector: Detector
    ) where Gateway: NewVerifiableGateway,
            Detector.Element == KripkeStatePropertyList,
            ViewFactory.View.State == KripkeState
    {
        let generator = VerificationStepGenerator()
        for (index, thread) in isolatedThreads.threads.enumerated() {
            if thread.map.steps.isEmpty {
                continue
            }
            let allFsmNames: Set<String> = Set(thread.map.steps.flatMap {
                $0.step.timeslots.flatMap(\.fsms)
            })
            let viewName = allFsmNames.count == 1 ? allFsmNames.first ?? "\(index)" : "\(index)"
            let view = viewFactory.make(identifier: viewName)
            defer { view.finish() }
            gateway.setScenario([], pool: thread.pool)
            let collapse = nil == thread.map.steps.first { $0.step.fsms.count > 1 }
            var cycleData = cycleDetector.initialData
            var jobs = [Job(step: 0, map: thread.map, pool: thread.pool, previous: nil)]
            var structure = KripkeStructure()
            while !jobs.isEmpty {
                let job = jobs.removeFirst()
                let step = job.map.steps[job.step]
                let previous = job.previous
                let newStep = job.step >= (job.map.steps.count - 1) ? 0 : job.step + 1
                defer {
                    if let previous = previous {
                        view.commit(state: previous.state)
                    }
                }
                switch step.step {
                case .takeSnapshot, .takeSnapshotAndStartTimeslot, .startTimeslot, .saveSnapshot:
                    let fsms = step.step.timeslots
                    let startTimeslot = step.step.startTimeslot
                    let fsm = startTimeslot ? fsms.first?.callChain.fsm(fromPool: job.pool) : nil
                    if fsm?.currentState.name == "SkipGarbage" {
                        print("Checking Skip_Garbage")
                    }
                    let pools: [FSMPool]
                    if step.step.takeSnapshot {
                        pools = generator.takeSnapshot(forFsms: fsms.map { $0.callChain.fsm(fromPool: job.pool) }, in: job.pool)
                    } else {
                        pools = [job.pool]
                    }
                    for pool in pools {
                        //print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(pool)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                        let properties = pool.propertyList(forStep: step.step, executingState: fsm?.currentState.name, collapseIfPossible: collapse)
                        if let previous = previous {
                            let edge: KripkeEdge = KripkeEdge(
                                clockName: fsm?.name,
                                constraint: nil,
                                resetClock: startTimeslot && (fsm.map { previous.resetClocks.contains($0.name) } ?? false),
                                takeSnapshot: startTimeslot,
                                time: previous.afterExecutingTimeUntil(
                                    time: step.time,
                                    cycleLength: isolatedThreads.cycleLength
                                ),
                                target: properties
                            )
                            previous.state.addEdge(edge)
                        }
                        guard !cycleDetector.inCycle(data: &cycleData, element: properties) else {
                            continue
                        }
                        let state = structure.state(for: properties, isInitial: previous == nil)
                        if step.step.saveSnapshot && job.map.hasFinished(forPool: pool) {
                            view.commit(state: state)
                            continue
                        }
                        let newResetClocks: Set<String>
                        if startTimeslot, let fsm = fsm {
                            newResetClocks = previous?.resetClocks.subtracting([fsm.name]) ?? []
                        } else {
                            newResetClocks = previous?.resetClocks ?? []
                        }
                        let newPrevious = Previous(state: state, time: step.time, resetClocks: newResetClocks)
                        jobs.append(Job(step: newStep, map: job.map, pool: pool.cloned, previous: newPrevious))
                    }
                case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                    let fsm = timeslot.callChain.fsm(fromPool: job.pool)
                    if fsm.currentState.name == "SkipGarbage" {
                        print("Executing Skip_Garbage: \(fsm.asScheduleableFiniteStateMachine)")
                    }
                    let currentState = fsm.currentState.name
                    let ringlets = generator.execute(timeslot: timeslot, inPool: job.pool, gateway: gateway, timer: timer)
                    for ringlet in ringlets {
                        //print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(ringlet.after)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                        let properties = ringlet.after.propertyList(forStep: step.step, executingState: currentState, collapseIfPossible: collapse)
                        let state = structure.state(for: properties, isInitial: previous == nil)
                        if let previous = previous {
                            let edge = KripkeEdge(
                                clockName: timeslot.callChain.fsm,
                                constraint: ringlet.condition == .lessThanEqual(value: 0) ? nil : ringlet.condition,
                                resetClock: false,
                                takeSnapshot: false,
                                time: previous.afterExecutingTimeUntil(
                                    time: step.time,
                                    cycleLength: isolatedThreads.cycleLength
                                ),
                                target: properties
                            )
                            previous.state.addEdge(edge)
                        }
                        guard !cycleDetector.inCycle(data: &cycleData, element: properties) else {
                            continue
                        }
                        if step.step.saveSnapshot && job.map.hasFinished(forPool: ringlet.after) {
                            view.commit(state: state)
                            continue
                        }
                        let resetClocks: Set<String>
                        if ringlet.transitioned {
                            resetClocks = (previous?.resetClocks ?? []).union([timeslot.callChain.fsm])
                        } else {
                            resetClocks = previous?.resetClocks ?? []
                        }
                        let newPrevious = Previous(state: state, time: step.time, resetClocks: resetClocks)
                        jobs.append(Job(step: newStep, map: job.map, pool: ringlet.after, previous: newPrevious))
                    }
                }
            }
        }
    }
    
}

extension AnyScheduleableFiniteStateMachine: CustomStringConvertible {
    
    public var description: String {
        "\(base)"
    }
    
}

extension AnySnapshotController: CustomStringConvertible {
    
    public var description: String {
        "\(base)"
    }
    
}

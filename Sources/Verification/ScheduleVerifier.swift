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
    
    var isolatedThreads: ScheduleIsolator
    
    init(schedule: Schedule, allFsms: FSMPool) {
        self.init(isolatedThreads: ScheduleIsolator(schedule: schedule, allFsms: allFsms))
    }
    
    init(isolatedThreads: ScheduleIsolator) {
        self.isolatedThreads = isolatedThreads
    }
    
    func verify<Gateway: ModifiableFSMGateway, Timer: Clock, View: KripkeStructureView, Detector: CycleDetector>(gateway: Gateway, timer: Timer, view: View, cycleDetector: Detector) where Gateway: NewVerifiableGateway, Detector.Element == KripkeStatePropertyList, View.State == KripkeState {
        verify(gateway: gateway, timer: timer, view: view, cycleDetector: cycleDetector, generator: ScheduleThreadVariations.self)
    }
    
    func verify<Gateway: ModifiableFSMGateway, Timer: Clock, View: KripkeStructureView, Detector: CycleDetector, VariationsGenerator: ScheduleThreadVariationsProtocol>(gateway: Gateway, timer: Timer, view: View, cycleDetector: Detector, generator: VariationsGenerator.Type) where Gateway: NewVerifiableGateway, Detector.Element == KripkeStatePropertyList, View.State == KripkeState {
        let generator = VerificationStepGenerator()
        defer {
            view.finish()
        }
        for thread in isolatedThreads.threads {
            if thread.map.steps.isEmpty {
                continue
            }
            let collapse = nil == thread.map.steps.first { $0.step.fsms.count > 1 }
            var cycleData = cycleDetector.initialData
            var jobs = [Job(step: 0, map: thread.map, pool: thread.pool, previous: nil)]
            var states: [KripkeStatePropertyList: KripkeState] = [:]
            states.reserveCapacity(100000)
            while !jobs.isEmpty {
                let job = jobs.removeFirst()
                let step = job.map.steps[job.step]
                print("\nGenerating \(step.step.marker) variations for: \(job.pool)\n")
                let previous = job.previous
                let newStep = job.step >= (job.map.steps.count - 1) ? 0 : job.step + 1
                switch step.step {
                case .takeSnapshot(let fsms):
                    let pools = generator.takeSnapshot(forFsms: fsms.map { $0.callChain.fsm(fromPool: job.pool) }, in: job.pool)
                    for pool in pools {
                        let properties = pool.propertyList(forStep: step.step, executingState: nil, collapseIfPossible: collapse)
                        let state = states[properties] ?? KripkeState(isInitial: previous == nil, properties: properties)
                        if nil == states[properties] {
                            states[properties] = state
                        }
                        if let previous = previous {
                            let edge = KripkeEdge(
                                clockName: nil,
                                constraint: nil,
                                resetClock: false,
                                takeSnapshot: true,
                                time: previous.afterExecutingTimeUntil(
                                    time: step.time,
                                    cycleLength: isolatedThreads.cycleLength
                                ),
                                target: properties
                            )
                            previous.state.addEdge(edge)
                        }
                        if !cycleDetector.inCycle(data: &cycleData, element: properties) {
                            let newPrevious = Previous(state: state, time: step.time, resetClocks: previous?.resetClocks ?? [])
                            jobs.append(Job(step: newStep, map: job.map, pool: pool, previous: newPrevious))
                        }
                    }
                case .takeSnapshotAndStartTimeslot(let timeslot):
                    let fsm = timeslot.callChain.fsm(fromPool: job.pool)
                    let pools = generator.takeSnapshot(forFsms: [fsm], in: job.pool)
                    for pool in pools {
                        let properties = pool.propertyList(forStep: step.step, executingState: fsm.currentState.name, collapseIfPossible: collapse)
                        let state = states[properties] ?? KripkeState(isInitial: previous == nil, properties: properties)
                        if nil == states[properties] {
                            states[properties] = state
                        }
                        if let previous = previous {
                            let edge = KripkeEdge(
                                clockName: timeslot.callChain.fsm,
                                constraint: nil,
                                resetClock: previous.resetClocks.contains(timeslot.callChain.fsm),
                                takeSnapshot: true,
                                time: previous.afterExecutingTimeUntil(
                                    time: step.time,
                                    cycleLength: isolatedThreads.cycleLength
                                ),
                                target: properties
                            )
                            previous.state.addEdge(edge)
                        }
                        if !cycleDetector.inCycle(data: &cycleData, element: properties) {
                            let resetClocks = previous?.resetClocks.subtracting([timeslot.callChain.fsm]) ?? []
                            let newPrevious = Previous(state: state, time: step.time, resetClocks: resetClocks)
                            jobs.append(Job(step: newStep, map: job.map, pool: pool, previous: newPrevious))
                        }
                    }
                case .startTimeslot(let timeslot):
                    let fsm = timeslot.callChain.fsm(fromPool: job.pool)
                    let properties = job.pool.propertyList(forStep: step.step, executingState: fsm.currentState.name, collapseIfPossible: collapse)
                    let state = states[properties] ?? KripkeState(isInitial: previous == nil, properties: properties)
                    if nil == states[properties] {
                        states[properties] = state
                    }
                    if let previous = previous {
                        let edge = KripkeEdge(
                            clockName: timeslot.callChain.fsm,
                            constraint: nil,
                            resetClock: previous.resetClocks.contains(timeslot.callChain.fsm),
                            takeSnapshot: true,
                            time: previous.afterExecutingTimeUntil(
                                time: step.time,
                                cycleLength: isolatedThreads.cycleLength
                            ),
                            target: properties
                        )
                        previous.state.addEdge(edge)
                    }
                    if !cycleDetector.inCycle(data: &cycleData, element: properties) {
                        let resetClocks = previous?.resetClocks.subtracting([timeslot.callChain.fsm]) ?? []
                        let newPrevious = Previous(state: state, time: step.time, resetClocks: resetClocks)
                        jobs.append(Job(step: newStep, map: job.map, pool: job.pool, previous: newPrevious))
                    }
                case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                    print("Execute: \(timeslot.callChain.fsm(fromPool: job.pool).asScheduleableFiniteStateMachine.base)")
                    print("Execute: \(job.pool)")
                    let currentState = timeslot.callChain.fsm(fromPool: job.pool).currentState.name
                    let ringlets = generator.execute(timeslot: timeslot, inPool: job.pool, gateway: gateway, timer: timer)
                    for ringlet in ringlets {
                        let properties = ringlet.after.propertyList(forStep: step.step, executingState: currentState, collapseIfPossible: collapse)
                        let state = states[properties] ?? KripkeState(isInitial: previous == nil, properties: properties)
                        if nil == states[properties] {
                            states[properties] = state
                        }
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
                        switch step.step {
                        case .executeAndSaveSnapshot:
                            if hasFinished(map: job.map, forPool: ringlet.after) {
                                view.commit(state: state)
                                continue
                            }
                        default:
                            break
                        }
                        if !cycleDetector.inCycle(data: &cycleData, element: properties) {
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
                case .saveSnapshot:
                    let properties = job.pool.propertyList(forStep: step.step, executingState: nil, collapseIfPossible: collapse)
                    let state = states[properties] ?? KripkeState(isInitial: previous == nil, properties: properties)
                    if nil == states[properties] {
                        states[properties] = state
                    }
                    if let previous = previous {
                        let edge = KripkeEdge(
                            clockName: nil,
                            constraint: nil,
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
                    if hasFinished(map: job.map, forPool: job.pool) {
                        view.commit(state: state)
                        continue
                    }
                    if !cycleDetector.inCycle(data: &cycleData, element: properties) {
                        let newPrevious = Previous(state: state, time: step.time, resetClocks: previous?.resetClocks ?? [])
                        jobs.append(Job(step: newStep, map: job.map, pool: job.pool, previous: newPrevious))
                    }
                }
                if let previous = previous {
                    view.commit(state: previous.state)
                }
            }
        }
    }
    
    private func hasFinished(map: VerificationMap, forPool pool: FSMPool) -> Bool {
        let fsms: Set<String> = Set(map.steps.lazy.flatMap(\.step.fsms))
        return nil == fsms.first { !pool.fsm($0).hasFinished }
    }
    
}

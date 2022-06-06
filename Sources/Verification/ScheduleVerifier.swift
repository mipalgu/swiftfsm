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
        
        var id: Int64
        
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

    func verify<Gateway: ModifiableFSMGateway, Timer: Clock>(gateway: Gateway, timer: Timer) throws -> [SQLiteKripkeStructure] where Gateway: NewVerifiableGateway {
        try self.verify(gateway: gateway, timer: timer, factory: SQLiteKripkeStructureFactory())
    }
    
    func verify<Gateway: ModifiableFSMGateway, Timer: Clock, Factory: MutableKripkeStructureFactory>(gateway: Gateway, timer: Timer, factory: Factory) throws -> [Factory.KripkeStructure] where Gateway: NewVerifiableGateway
    {
        var stores: [Factory.KripkeStructure] = []
        for (index, thread) in isolatedThreads.threads.enumerated() {
            let allFsmNames: Set<String> = Set(thread.map.steps.flatMap {
                $0.step.timeslots.flatMap(\.fsms)
            })
            let identifier = allFsmNames.count == 1 ? allFsmNames.first ?? "\(index)" : "\(index)"
            let structure = try verify(thread: thread, identifier: identifier, gateway: gateway, timer: timer, factory: factory)
            stores.append(structure)
        }
        return stores
    }

    func verify<Gateway: ModifiableFSMGateway, Timer: Clock, Factory: MutableKripkeStructureFactory>(thread: IsolatedThread, identifier: String, gateway: Gateway, timer: Timer, factory: Factory) throws -> Factory.KripkeStructure where Gateway: NewVerifiableGateway
    {
        let persistentStore = try factory.make(identifier: identifier)
        if thread.map.steps.isEmpty {
            return persistentStore
        }
        let generator = VerificationStepGenerator()
        gateway.setScenario([], pool: thread.pool)
        let collapse = nil == thread.map.steps.first { $0.step.fsms.count > 1 }
        var jobs = [Job(step: 0, map: thread.map, pool: thread.pool, previous: nil)]
        jobs.reserveCapacity(100000)
        while !jobs.isEmpty {
            let job = jobs.removeLast()
            let step = job.map.steps[job.step]
            let previous = job.previous
            let newStep = job.step >= (job.map.steps.count - 1) ? 0 : job.step + 1
            // Handle parameterised machine delegates
            if step.step.startTimeslot,
                let timeslot = step.step.timeslots.first,
                let call = timeslot.callChain.calls.last,
                job.map.delegates.contains(timeslot.callChain.fsm)
            {
                let writeStep = job.map.steps[newStep]
                let newStep = newStep >= (job.map.steps.count - 1) ? 0 : newStep + 1
                let fsm = timeslot.callChain.fsm
                let results = delegate(call: call)
                let properties = job.pool.propertyList(forStep: .startTimeslot(timeslot: timeslot), executingState: nil, collapseIfPossible: collapse)
                let inCycle = try persistentStore.exists(properties)
                let id: Int64
                if inCycle {
                    id = try persistentStore.id(for: properties)
                } else {
                    id = try persistentStore.add(properties, isInitial: previous == nil)
                }
                if let previous = previous {
                    let edge: KripkeEdge = KripkeEdge(
                        clockName: fsm,
                        constraint: nil,
                        resetClock: previous.resetClocks.contains(fsm),
                        takeSnapshot: true,
                        time: previous.afterExecutingTimeUntil(
                            time: step.time,
                            cycleLength: isolatedThreads.cycleLength
                        ),
                        target: properties
                    )
                    try persistentStore.add(edge: edge, to: previous.id)
                }
                guard !inCycle else {
                    continue
                }
                let newResetClocks = previous?.resetClocks.subtracting([fsm]) ?? []
                guard !results.results.isEmpty else {
                    let target = job.pool.propertyList(forStep: .execute(timeslot: timeslot), executingState: nil, collapseIfPossible: true)
                    let targetId: Int64 = try persistentStore.add(target, isInitial: false)
                    let edge = KripkeEdge(
                        clockName: fsm,
                        constraint: nil,
                        resetClock: false,
                        takeSnapshot: false,
                        time: timeslot.duration,
                        target: target
                    )
                    try persistentStore.add(edge: edge, to: targetId)
                    let newPrevious = Previous(id: targetId, time: writeStep.time, resetClocks: newResetClocks)
                    jobs.append(Job(step: newStep, map: job.map, pool: job.pool.cloned, previous: newPrevious))
                    continue
                }
                for (range, result) in results.results {
                    var resultPool = job.pool.cloned
                    resultPool.handleFinishedCall(for: fsm, result: result)
                    let target = resultPool.propertyList(forStep: .execute(timeslot: timeslot), executingState: nil, collapseIfPossible: true)
                    let targetId: Int64 = try persistentStore.add(target, isInitial: false)
                    let edge: KripkeEdge
                    switch range {
                    case .greaterThan(let time):
                        edge = KripkeEdge(
                            clockName: fsm,
                            constraint: .greaterThan(value: time),
                            resetClock: false,
                            takeSnapshot: false,
                            time: timeslot.duration,
                            target: target
                        )
                    case .range(let range):
                        edge = KripkeEdge(
                            clockName: fsm,
                            constraint: .and(lhs: .greaterThanEqual(value: range.lowerBound), rhs: .lessThanEqual(value: range.upperBound)),
                            resetClock: false,
                            takeSnapshot: false,
                            time: timeslot.duration,
                            target: target
                        )
                    }
                    try persistentStore.add(edge: edge, to: targetId)
                    let newPrevious = Previous(id: targetId, time: writeStep.time, resetClocks: newResetClocks)
                    jobs.append(Job(step: newStep, map: job.map, pool: resultPool.cloned, previous: newPrevious))
                }
                let target = job.pool.propertyList(forStep: .execute(timeslot: timeslot), executingState: nil, collapseIfPossible: true)
                let targetId: Int64 = try persistentStore.add(target, isInitial: false)
                let extraEdge = KripkeEdge(
                    clockName: fsm,
                    constraint: .lessThan(value: results.bound),
                    resetClock: false,
                    takeSnapshot: false,
                    time: timeslot.duration,
                    target: target
                )
                try persistentStore.add(edge: extraEdge, to: targetId)
                let newPrevious = Previous(id: targetId, time: writeStep.time, resetClocks: newResetClocks)
                jobs.append(Job(step: newStep, map: job.map, pool: job.pool.cloned, previous: newPrevious))
                continue
            }
            // Handle inline jobs.
            switch step.step {
            case .takeSnapshot, .takeSnapshotAndStartTimeslot, .startTimeslot, .saveSnapshot:
                let fsms = step.step.timeslots.filter { !job.map.delegates.contains($0.callChain.fsm) }
                let startTimeslot = step.step.startTimeslot
                let fsm = startTimeslot ? fsms.first?.callChain.fsm(fromPool: job.pool) : nil
                let pools: [FSMPool]
                if step.step.takeSnapshot {
                    pools = generator.takeSnapshot(forFsms: fsms.map { $0.callChain.fsm(fromPool: job.pool) }, in: job.pool)
                } else {
                    pools = [job.pool]
                }
                for pool in pools {
                    //print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(pool)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                    let properties = pool.propertyList(forStep: step.step, executingState: fsm?.currentState.name, collapseIfPossible: collapse)
                    let inCycle = try persistentStore.exists(properties)
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: previous == nil)
                    } else {
                        id = try persistentStore.id(for: properties)
                    }
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
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    guard !inCycle else {
                        continue
                    }
                    if step.step.saveSnapshot && job.map.hasFinished(forPool: pool) {
                        continue
                    }
                    let newResetClocks: Set<String>
                    if startTimeslot, let fsm = fsm {
                        newResetClocks = previous?.resetClocks.subtracting([fsm.name]) ?? []
                    } else {
                        newResetClocks = previous?.resetClocks ?? []
                    }
                    let newPrevious = Previous(id: id, time: step.time, resetClocks: newResetClocks)
                    jobs.append(Job(step: newStep, map: job.map, pool: pool.cloned, previous: newPrevious))
                }
            case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                let fsm = timeslot.callChain.fsm(fromPool: job.pool)
                let currentState = fsm.currentState.name
                let ringlets = generator.execute(timeslot: timeslot, inPool: job.pool, gateway: gateway, timer: timer)
                for ringlet in ringlets {
                    //print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(ringlet.after)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                    var newMap = job.map
                    var newPool = ringlet.after
                    var callees: Set<String> = []
                    for call in ringlet.calls {
                        let callerName = gateway.fsm(fromID: call.caller).name
                        let calleeName = gateway.parameterisedFSM(fromID: call.callee).name
                        callees.insert(calleeName)
                        if job.map.delegates.contains(calleeName) {
                            newPool.handleCall(to: calleeName, parameters: call.parameters)
                            newMap.handleCall(from: callerName, to: calleeName, data: call)
                        }
                    }
                    let properties = newPool.propertyList(forStep: step.step, executingState: currentState, collapseIfPossible: collapse)
                    let inCycle = try persistentStore.exists(properties)
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: previous == nil)
                    } else {
                        id = try persistentStore.id(for: properties)
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
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    guard !inCycle else {
                        continue
                    }
                    if step.step.saveSnapshot && job.map.hasFinished(forPool: ringlet.after) {
                        continue
                    }
                    let resetClocks: Set<String>
                    if ringlet.transitioned {
                        resetClocks = (previous?.resetClocks ?? []).union([timeslot.callChain.fsm]).union(callees)
                    } else {
                        resetClocks = (previous?.resetClocks ?? []).union(callees)
                    }
                    let newPrevious = Previous(id: id, time: step.time, resetClocks: resetClocks)
                    jobs.append(Job(step: newStep, map: newMap, pool: ringlet.after, previous: newPrevious))
                }
            }
        }
        return persistentStore
    }

    struct CallResults {

        var bound: UInt

        var results: [(ClockRange, Any?)]

    }

    enum ClockRange {

        case greaterThan(UInt)
        case range(ClosedRange<UInt>)

    }

    private func delegate(call _: Call) -> CallResults { CallResults(bound: 0, results: []) }
    
}

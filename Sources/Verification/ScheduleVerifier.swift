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
import swift_helpers

final class ScheduleVerifier<Isolator: ScheduleIsolatorProtocol> {
    
    private struct Previous {
        
        var id: Int64
        
        var time: UInt
        
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

        var cycleCount: UInt

        var promises: [String: PromiseData]

        var previousNodes: Set<Int64>
        
        var previous: Previous?

        var resetClocks: Set<String>?
        
    }
    
    let isolatedThreads: Isolator

    private var resultsCache: [CallKey: CallResults] = [:]

    private var stores: [String: Any] = [:]
    
    convenience init(schedule: Schedule, allFsms: FSMPool) where Isolator == ScheduleIsolator {
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
        stores = [:]
        resultsCache = [:]
        for (index, thread) in isolatedThreads.threads.enumerated() {
            let allFsmNames: Set<String> = Set(thread.map.steps.flatMap {
                $0.step.timeslots.flatMap(\.fsms)
            })
            let filtered = allFsmNames.filter { thread.pool.parameterisedFSMs.keys.contains($0) }
            let identifier = filtered.count == 1 ? filtered.first ?? "\(index)" : "\(index)"
            try verify(thread: thread, identifier: identifier, gateway: gateway, timer: timer, factory: factory, recordingResultsFor: nil)
        }
        return stores.values.map { $0 as! Factory.KripkeStructure }
    }

    @discardableResult
    func verify<Gateway: ModifiableFSMGateway, Timer: Clock, Factory: MutableKripkeStructureFactory>(thread: IsolatedThread, identifier: String, gateway: Gateway, timer: Timer, factory: Factory, recordingResultsFor resultsFsm: String?) throws -> CallResults where Gateway: NewVerifiableGateway
    {
        let persistentStore = try (stores[identifier] as? Factory.KripkeStructure) ?? factory.make(identifier: identifier)
        defer { self.stores[identifier] = persistentStore }
        var callResults = CallResults()
        if thread.map.steps.isEmpty {
            if let resultsFsm = resultsFsm {
                fatalError("Thread is empty for calling \(resultsFsm)")
            }
            return callResults
        }
        let generator = VerificationStepGenerator()
        gateway.setScenario([], pool: thread.pool)
        var cyclic: Bool? = nil
        let collapse = nil == thread.map.steps.first { $0.step.fsms.count > 1 }
        var jobs = [Job(step: 0, map: thread.map, pool: thread.pool, cycleCount: 0, promises: [:], previousNodes: [], previous: nil, resetClocks: Set(thread.pool.fsms.map(\.name).filter { thread.pool.parameterisedFSMs[$0] == nil }))]
        jobs.reserveCapacity(100000)
        while !jobs.isEmpty {
            let job = jobs.removeLast()
            let step = job.map.steps[job.step]
            let previous = job.previous
            let newStep = job.step >= (job.map.steps.count - 1) ? 0 : job.step + 1
            // Handle Delegate steps.
            delegateSwitch: switch step.step {
            case .startDelegates, .takeSnapshotAndStartTimeslot, .startTimeslot:
                switch step.step {
                case .takeSnapshotAndStartTimeslot(let timeslot), .startTimeslot(let timeslot):
                    if timeslot.callChain.calls.isEmpty {
                        break delegateSwitch
                    }
                default:
                    break
                }
                let timeslots = step.step.timeslots
                var previous = previous
                var resetClocks = job.resetClocks
                var allInCycle = true
                var subCycle = false
                var previousNodes = job.previousNodes
                for timeslot in timeslots.sorted(by: { $0.callChain.fsm < $1.callChain.fsm }) {
                    let shouldReset = resetClocks?.contains(timeslot.callChain.fsm)
                    resetClocks?.subtract([timeslot.callChain.fsm])
                    let properties = job.pool.propertyList(forStep: .startDelegates(fsms: [timeslot]), executingState: nil, promises: job.promises, resetClocks: resetClocks, collapseIfPossible: true)
                    let inCycle = try persistentStore.exists(properties)
                    allInCycle = allInCycle && inCycle
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: job.initial)
                    } else {
                        id = try persistentStore.id(for: properties)
                        if job.initial {
                            try persistentStore.markAsInitial(id: id)
                        }
                    }
                    subCycle = subCycle || previousNodes.contains(id)
                    previousNodes.formUnion([id])
                    if let previous = previous {
                        let edge: KripkeEdge = KripkeEdge(
                            clockName: timeslot.callChain.fsm,
                            constraint: nil,
                            resetClock: shouldReset ?? false,
                            takeSnapshot: true,
                            time: previous.afterExecutingTimeUntil(
                                time: step.time,
                                cycleLength: isolatedThreads.cycleLength
                            ),
                            target: properties
                        )
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    previous = Previous(id: id, time: step.time)
                }
                guard !allInCycle else {
                    if let resultsFsm = resultsFsm {
                        if subCycle {
                            fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                        }
                        guard let c = cyclic else {
                            cyclic = true
                            continue
                        }
                        guard c else {
                            fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                        }
                        cyclic = true
                    }
                    continue
                }
                let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                jobs.append(Job(step: newStep, map: job.map, pool: job.pool, cycleCount: newCycleCount, promises: job.promises, previousNodes: previousNodes, previous: previous, resetClocks: resetClocks))
                continue
            case .endDelegates, .execute, .executeAndSaveSnapshot:
                switch step.step {
                case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                    if timeslot.callChain.calls.isEmpty {
                        break delegateSwitch
                    }
                default:
                    break
                }
                let timeslots = step.step.timeslots
                let executing = timeslots.filter { job.pool.parameterisedFSMs[$0.callChain.fsm]?.status == .executing }
                let remainingTimeslots = timeslots.subtracting(executing)
                let pathways = try processDelegate(gateway: gateway, timer: timer, factory: factory, time: step.time, map: job.map, pool: job.pool, promises: job.promises, resetClocks: job.resetClocks, previous: job.previous, timeslots: executing, addingTo: persistentStore)
                var newPrevious: [Previous] = []
                if !remainingTimeslots.isEmpty {
                    for (pool, map, previous) in pathways.isEmpty ? [(job.pool, job.map, [job.previous].map { $0 })] : pathways {
                        let properties = pool.propertyList(forStep: .endDelegates(fsms: remainingTimeslots), executingState: nil, promises: job.promises, resetClocks: job.resetClocks, collapseIfPossible: true)
                        let inCycle = try persistentStore.exists(properties)
                        let id: Int64
                        if !inCycle {
                            id = try persistentStore.add(properties, isInitial: false)
                        } else {
                            id = try persistentStore.id(for: properties)
                        }
                        var previousNodes = job.previousNodes
                        for previous in previous {
                            if let previous = previous {
                                let edge: KripkeEdge = KripkeEdge(
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
                                try persistentStore.add(edge: edge, to: previous.id)
                                previousNodes.formUnion([previous.id])
                                newPrevious.append(previous)
                            }
                        }
                        guard !inCycle else {
                            if let resultsFsm = resultsFsm {
                                guard let c = cyclic else {
                                    if job.previousNodes.contains(id) {
                                        cyclic = true
                                    }
                                    continue
                                }
                                if !job.previousNodes.contains(id) {
                                    continue
                                }
                                guard c else {
                                    fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                                }
                            }
                            continue
                        }
                        let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                        let newPrevious = Previous(id: id, time: step.time)
                        jobs.append(Job(step: newStep, map: map, pool: pool, cycleCount: newCycleCount, promises: job.promises, previousNodes: previousNodes.union([id]), previous: newPrevious, resetClocks: job.resetClocks))
                    }
                } else {
                    for (pool, map, previous) in pathways {
                        for previous in previous {
                            if let previous = previous {
                                let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                                jobs.append(Job(step: newStep, map: map, pool: pool, cycleCount: newCycleCount, promises: job.promises, previousNodes: job.previousNodes.union([previous.id]), previous: previous, resetClocks: job.resetClocks))
                            }
                        }
                    }
                }
                continue
            default:
                break
            }
            // Handle inline steps.
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
                    let properties = pool.propertyList(forStep: step.step, executingState: fsm?.currentState.name, promises: job.promises, resetClocks: job.resetClocks, collapseIfPossible: collapse)
                    let inCycle = try persistentStore.exists(properties)
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: previous == nil)
                    } else {
                        id = try persistentStore.id(for: properties)
                        if job.initial {
                            try persistentStore.markAsInitial(id: id)
                        }
                    }
                    if let previous = previous {
                        let edge: KripkeEdge = KripkeEdge(
                            clockName: fsm?.name,
                            constraint: nil,
                            resetClock: startTimeslot && (fsm.map { job.resetClocks?.contains($0.name) ?? false } ?? false),
                            takeSnapshot: startTimeslot,
                            time: previous.afterExecutingTimeUntil(
                                time: step.time,
                                cycleLength: isolatedThreads.cycleLength
                            ),
                            target: properties
                        )
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    if step.step.saveSnapshot && job.map.hasFinished(forPool: pool) {
                        if let resultsFsm = resultsFsm {
                            guard let parameterisedFSM = pool.fsm(resultsFsm).asParameterisedFiniteStateMachine else {
                                fatalError("Attempting to record results for a non-parameterised fsm")
                            }
                            callResults.insert(result: parameterisedFSM.resultContainer.result, forTime: job.cycleCount * isolatedThreads.cycleLength + step.time)
                            guard let c = cyclic else {
                                cyclic = false
                                continue
                            }
                            guard !c else {
                                fatalError("Attempting to record results for a cyclic fsm.")
                            }
                            cyclic = false
                        }
                        continue
                    }
                    guard !inCycle else {
                        if let resultsFsm = resultsFsm {
                            guard let c = cyclic else {
                                if job.previousNodes.contains(id) {
                                    cyclic = true
                                }
                                continue
                            }
                            if !job.previousNodes.contains(id) {
                                continue
                            }
                            guard c else {
                                fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                            }
                        }
                        continue
                    }
                    let newResetClocks: Set<String>?
                    if startTimeslot, let fsm = fsm {
                        newResetClocks = job.resetClocks.map { $0.subtracting([fsm.name]) }
                    } else {
                        newResetClocks = job.resetClocks
                    }
                    let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                    let newPrevious = Previous(id: id, time: step.time)
                    let newPromises = job.promises.filter { !properties.contains(object: $1) }
                    jobs.append(Job(step: newStep, map: job.map, pool: pool.cloned, cycleCount: newCycleCount, promises: newPromises, previousNodes: job.previousNodes.union([id]), previous: newPrevious, resetClocks: newResetClocks))
                }
            case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                let fsm = timeslot.callChain.fsm(fromPool: job.pool)
                let currentState = fsm.currentState.name
                let ringlets = generator.execute(timeslot: timeslot, promises: job.promises, inPool: job.pool, gateway: gateway, timer: timer)
                for ringlet in ringlets {
                    //print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(ringlet.after)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                    var newMap = job.map
                    var newPool = ringlet.after
                    newPool.parameterisedFSMs.merge(job.pool.parameterisedFSMs) { (lhs, _) in lhs }
                    var callees: Set<String> = []
                    var newPromises: [String: PromiseData] = [:]
                    for call in ringlet.calls {
                        callees.insert(call.callee.name)
                        newPromises[call.callee.name] = call.promiseData
                        if job.map.delegates.contains(call.callee.name) {
                            newPool.handleCall(to: call.callee.name, parameters: call.parameters)
                            newMap.handleCall(call)
                        }
                    }
                    let mergedPromises = job.promises.merging(newPromises) { (_, _) in
                        fatalError("Detected calling same machine more than once.")
                    }
                    let resetClocks: Set<String>?
                    if ringlet.transitioned {
                        resetClocks = job.resetClocks.map { $0.union([timeslot.callChain.fsm]).union(callees) }
                    } else {
                        resetClocks = job.resetClocks.map { $0.union(callees) }
                    }
                    let properties = newPool.propertyList(forStep: step.step, executingState: currentState, promises: mergedPromises, resetClocks: resetClocks, collapseIfPossible: collapse)
                    let inCycle = try persistentStore.exists(properties)
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: previous == nil)
                    } else {
                        id = try persistentStore.id(for: properties)
                        if job.initial {
                            try persistentStore.markAsInitial(id: id)
                        }
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
                    if step.step.saveSnapshot && job.map.hasFinished(forPool: ringlet.after) {
                        if let resultsFsm = resultsFsm {
                            guard let parameterisedFSM = ringlet.after.fsm(resultsFsm).asParameterisedFiniteStateMachine else {
                                fatalError("Attempting to record results for a non-parameterised fsm")
                            }
                            callResults.insert(result: parameterisedFSM.resultContainer.result, forTime: job.cycleCount * isolatedThreads.cycleLength + step.time)
                            guard let c = cyclic else {
                                cyclic = false
                                continue
                            }
                            guard !c else {
                                fatalError("Attempting to record results for a cyclic fsm")
                            }
                            cyclic = false
                        }
                        continue
                    }
                    guard !inCycle else {
                        if let resultsFsm = resultsFsm {
                            guard let c = cyclic else {
                                if job.previousNodes.contains(id) {
                                    cyclic = true
                                }
                                continue
                            }
                            if !job.previousNodes.contains(id) {
                                continue
                            }
                            guard c else {
                                fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                            }
                        }
                        continue
                    }
                    let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                    let newPrevious = Previous(id: id, time: step.time)
                    let filteredPromises = mergedPromises.filter { !properties.contains(object: $1) }
                    jobs.append(Job(step: newStep, map: newMap, pool: newPool, cycleCount: newCycleCount, promises: filteredPromises, previousNodes: job.previousNodes.union([id]), previous: newPrevious, resetClocks: resetClocks))
                }
            case .startDelegates, .endDelegates:
                fatalError("Attempting to handle delegate step in inline step section.")
            }
        }
        return callResults
    }

    private func processDelegate<
        Gateway: ModifiableFSMGateway,
        Timer: Clock,
        Factory: MutableKripkeStructureFactory,
        C: Collection,
        Structure: MutableKripkeStructure
    >(
        gateway: Gateway,
        timer: Timer,
        factory: Factory,
        time: UInt,
        map: VerificationMap,
        pool: FSMPool,
        promises: [String: PromiseData],
        resetClocks: Set<String>?,
        previous: Previous?,
        timeslots: C,
        addingTo structure: Structure
    ) throws -> [(FSMPool, VerificationMap, [Previous?])] where
        Gateway: NewVerifiableGateway,
        C.Element == Timeslot,
        C.SubSequence: Collection,
        C.SubSequence.Element == Timeslot,
        C.SubSequence.SubSequence == C.SubSequence
    {
        guard let timeslot = timeslots.first, let call = timeslot.callChain.calls.last else {
            return [(pool, map, previous.map { [$0] } ?? [])]
        }
        let results = try self.delegate(call: call, callee: call.callee.name, gateway: gateway, timer: timer, factory: factory)
        var out: [(FSMPool, VerificationMap, [Previous?])] = []
        for result in results.results {
            var resultPool = pool.cloned
            resultPool.handleFinishedCall(for: timeslot.callChain.fsm, result: result.1)
            var newMap = map
            newMap.handleFinishedCall(call)
            let properties = resultPool.propertyList(forStep: .endDelegates(fsms: [timeslot]), executingState: nil, promises: promises, resetClocks: resetClocks, collapseIfPossible: true)
            let inCycle = try structure.exists(properties)
            let id: Int64
            if !inCycle {
                id = try structure.add(properties, isInitial: previous == nil)
            } else {
                id = try structure.id(for: properties)
                if previous == nil {
                    try structure.markAsInitial(id: id)
                }
            }
            let range = result.0
            if let previous = previous {
                let edge: KripkeEdge
                switch range {
                case .greaterThanEqual(let greaterThanTime):
                    edge = KripkeEdge(
                        clockName: timeslot.callChain.fsm,
                        constraint: .greaterThanEqual(value: greaterThanTime),
                        resetClock: false,
                        takeSnapshot: false,
                        time: previous.afterExecutingTimeUntil(
                            time: time,
                            cycleLength: isolatedThreads.cycleLength
                        ),
                        target: properties
                    )
                case .range(let range):
                    edge = KripkeEdge(
                        clockName: timeslot.callChain.fsm,
                        constraint: .and(lhs: .greaterThanEqual(value: range.lowerBound), rhs: .lessThan(value: range.upperBound)),
                        resetClock: false,
                        takeSnapshot: false,
                        time: previous.afterExecutingTimeUntil(
                            time: time,
                            cycleLength: isolatedThreads.cycleLength
                        ),
                        target: properties
                    )
                }
                try structure.add(edge: edge, to: previous.id)
            }
            if inCycle {
                continue
            }
            out.append(contentsOf: try processDelegate(gateway: gateway, timer: timer, factory: factory, time: time, map: newMap, pool: resultPool, promises: promises, resetClocks: resetClocks, previous: Previous(id: id, time: time), timeslots: timeslots.dropFirst(), addingTo: structure))
        }
        let properties = pool.propertyList(forStep: .endDelegates(fsms: [timeslot]), executingState: nil, promises: promises, resetClocks: resetClocks, collapseIfPossible: true)
        let inCycle = try structure.exists(properties)
        let id: Int64
        if !inCycle {
            id = try structure.add(properties, isInitial: previous == nil)
        } else {
            id = try structure.id(for: properties)
            if previous == nil {
                try structure.markAsInitial(id: id)
            }
        }
        if let previous = previous {
            let extraEdge = KripkeEdge(
                clockName: timeslot.callChain.fsm,
                constraint: results.results.isEmpty ? nil : .lessThan(value: results.bound),
                resetClock: false,
                takeSnapshot: false,
                time: previous.afterExecutingTimeUntil(
                    time: time,
                    cycleLength: isolatedThreads.cycleLength
                ),
                target: properties
            )
            try structure.add(edge: extraEdge, to: previous.id)
        }
        if inCycle {
            return out
        }
        out.append(contentsOf: try processDelegate(gateway: gateway, timer: timer, factory: factory, time: time, map: map, pool: pool, promises: promises, resetClocks: resetClocks, previous: Previous(id: id, time: time), timeslots: timeslots.dropFirst(), addingTo: structure))
        return out
    }

    struct CallResults {

        var bound: UInt = 0

        private var times: SortedCollection = SortedCollection<(UInt, Any?, KripkeStateProperty)> {
            if $0.0 < $1.0 {
                return .orderedAscending
            } else if $0.0 > $1.0 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }

        var results: [(ClockRange, Any?)] {
            if times.isEmpty {
                return []
            }
            let grouped = times.grouped {
                $0.0 == $1.0
            }
            guard let last = grouped.last?.map({ (ClockRange.greaterThanEqual($0.0), $0.1) }) else {
                return []
            }
            if grouped.count == 1 {
                return last
            }
            let zipped = zip(grouped, grouped.dropFirst())
            let ranges = zipped.flatMap { (lhs, rhs) -> [(ClockRange, Any?)] in
                guard let lhsTime = lhs.first?.0, let rhsTime = rhs.first?.0 else {
                    fatalError("Grouped elements results in empty array")
                }
                return lhs.map { (ClockRange.range(lhsTime..<rhsTime), $0.1) }
            }
            return ranges + last
        }

        init() {}

        mutating func insert(result: Any?, forTime time: UInt) {
            let plist = KripkeStateProperty(result)
            let element = (time, result, plist)
            let range = times.range(of: element)
            guard !times[range].contains(where: { $0.2 == plist }) else {
                return
            }
            times.insert(element)
            bound = times.last?.0 ?? 0
        }

    }

    enum ClockRange {

        case greaterThanEqual(UInt)
        case range(Range<UInt>)

    }

    struct CallKey: Hashable {

        var callee: String

        var parameters: [String: Any?]

        static func ==(lhs: CallKey, rhs: CallKey) -> Bool {
            KripkeStatePropertyList(lhs) == KripkeStatePropertyList(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(KripkeStatePropertyList(self))
        }

    }

    private func delegate<Gateway: ModifiableFSMGateway, Timer: Clock, Factory: MutableKripkeStructureFactory>(call: Call, callee: String, gateway: Gateway, timer: Timer, factory: Factory) throws -> CallResults where Gateway: NewVerifiableGateway
    {
        let key = CallKey(callee: call.callee.name, parameters: call.parameters)
        if let results = resultsCache[key] {
            return results
        }
        guard var thread = isolatedThreads.thread(forFsm: callee) else {
            fatalError("No thread provided for calling \(callee)")
        }
        thread.setParameters(of: callee, to: call.parameters)
        let results = try verify(thread: thread, identifier: callee, gateway: gateway, timer: timer, factory: factory, recordingResultsFor: callee)
        resultsCache[key] = results
        return results
    }
    
}

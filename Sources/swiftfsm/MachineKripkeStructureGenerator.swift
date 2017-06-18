/*
 * MachineKripkeStructureGenerator.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 10/06/2017.
 * Copyright © 2017 Callum McColl. All rights reserved.
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

import KripkeStructure
import FSM

public final class MachineKripkeStructureGenerator<
    Detector: CycleDetector,
    Extractor: ExternalsSpinnerDataExtractorType,
    Constructor: MultipleExternalsSpinnerConstructorType,
    Tokenizer: SchedulerTokenizer
>: KripkeStructureGenerator where 
    Detector.Element == World,
    Tokenizer.Object == Machine,
    Tokenizer.SchedulerToken == AnyScheduleableFiniteStateMachine
{

    private typealias ExternalsData = (
        externalVariables: AnySnapshotController,
        defaultValues: KripkeStatePropertyList,
        spinners: [String: (Any) -> Any?]
    )

    private struct Job {

        let cache: Detector.Data

        let lastSnapshot: World

        let tokens: [[(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)]]
        
        let executing: Int

        let lastState: KripkeState?

        let lastRecords: [[KripkeStatePropertyList]]

    }

    private let cycleDetector: Detector
    
    private let extractor: Extractor

    private let machines: [Machine]

    private let spinnerConstructor: Constructor

    private let tokenizer: Tokenizer

    public init(
        cycleDetector: Detector,
        extractor: Extractor,
        machines: [Machine],
        spinnerConstructor: Constructor,
        tokenizer: Tokenizer
    ) {
        self.cycleDetector = cycleDetector
        self.extractor = extractor
        self.machines = machines
        self.spinnerConstructor = spinnerConstructor
        self.tokenizer = tokenizer
    }

    public func generate() -> KripkeStructure {
        var states: [[KripkeState]] = []
        // Create spinner.
        let machines = self.fetchUniqueMachines(fromMachines: self.machines)
        guard false == machines.isEmpty else {
            return KripkeStructure(states: [])
        }
        let (data, externalCounts) = self.makeExternalsData(forMachines: machines)
        // Create initial jobs.
        let tokens = tokenizer.separate(self.machines)
        var jobs = [MachineKripkeStructureGenerator.Job(
            cache: self.cycleDetector.initialData,
            lastSnapshot: World(externalVariables: [:], variables: [:]),
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { $0.0.currentRecord } }
        )]
        // Loop until we run out of jobs.
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            // Execute the tokens for the current job for all variations of external variables.
            let spinner = self.spinnerConstructor.makeSpinner(forExternals: data.flatMap { $0 })
            while let externals = spinner() {
                // Clone all fsms.
                let clones = job.tokens.enumerated().map {
                    self.clone(
                        tokens: $1,
                        andAssignExternals: externals,
                        withExternalCounts: externalCounts,
                        andLastRecords: job.lastRecords[$0]
                    )
                }
                // Check for cycles.
                let world = self.createWorld(fromExternals: externals, andTokens: clones, andLastWorld: job.lastSnapshot)
                let (inCycle, newCache) = self.cycleDetector.inCycle(data: job.cache, element: world)
                if true == inCycle {
                    continue
                }
                // Create a `KripkeState` for each ringlet executing in each fsm.
                let tempStates = execute(clones: clones[job.executing], withLastState: job.lastState)
                // Append the states to the states array if these are starting states.
                if (nil == job.lastState) {
                    states.append(tempStates)
                }
                // Create a new job from the clones.
                jobs.append(MachineKripkeStructureGenerator.Job(
                    cache: newCache,
                    lastSnapshot: self.createWorld(fromExternals: externals, andTokens: clones, andLastWorld: world),
                    tokens: clones,
                    executing: (job.executing + 1) % clones.count,
                    lastState: tempStates.last,
                    lastRecords: clones.map { $0.map { $0.0.currentRecord } }
                ))
            }
        }
        return KripkeStructure(states: states)
    }

    private func execute(clones: [(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)], withLastState last: KripkeState?) -> [KripkeState] {
        var last = last
        return clones.flatMap { (fsm: AnyScheduleableFiniteStateMachine, machine: Machine) -> [KripkeState] in
            let preState = self.generateKripkeState(from: fsm, within: machine, withLastState: last)
            last = preState
            fsm.next()
            let postState = self.generateKripkeState(from: fsm, within: machine, withLastState: last)
            last = postState
            return [preState, postState]
        }
    }

    private func generateKripkeState(from fsm: AnyScheduleableFiniteStateMachine, within machine: Machine, withLastState last: KripkeState?) -> KripkeState {
        let state = KripkeState(
            id: "\(machine.name).\(fsm.name)",
            properties: fsm.currentRecord,
            previous: last,
            targets: []
        )
        last?.targets.append(state)
        return state
    }

    private func fetchUniqueMachines(fromMachines machines: [Machine]) -> Set<Machine> {
        var uniqueMachines: Set<Machine> = []
        machines.forEach {
            uniqueMachines.insert($0)
        }
        return uniqueMachines
    }

    private func makeExternalsData(forMachines: Set<Machine>) -> ([ExternalsData], [Machine: (Int, Int)]) {
        var externalCounts: [Machine: (Int, Int)] = [:]
        var i = 0
        var lastCount = 0
        let data = machines.flatMap { (machine: Machine) -> [ExternalsData] in 
            guard let fsm = machine.fsms.first else {
                return []
            }
            let d = fsm.externalVariables.map { (e: AnySnapshotController) -> ExternalsData in
                let (defaultValues, spinners) = self.extractor.extract(
                    externalVariables: e
                )
                return (
                    externalVariables: e,
                    defaultValues: defaultValues,
                    spinners: spinners
                )
            }
            externalCounts[machine] = (i, d.count)
            lastCount = d.count
            i += lastCount 
            return d
        }
        return (data, externalCounts)
    }

    private func fetchValues(fromList list: KripkeStatePropertyList) -> [String: Any] {
        var ps: [String: Any] = [:]
        list.forEach {
            switch $1.type {
            case .Compound(let l):
                ps[$0] = self.fetchValues(fromList: l)
            default:
                ps[$0] = $1.value
            }
        }
        return ps
    }
    
    private func createWorld(
        fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andTokens tokens: [[(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)]],
        andLastWorld lastWorld: World
    ) -> World {
        var ps: KripkeStatePropertyList = [:]
        externals.enumerated().forEach {
            ps["\($0)"] = KripkeStateProperty(type: .Compound($1.1), value: $1.0.val)
        }
        var varPs: KripkeStatePropertyList = [:]
        tokens.forEach {
            $0.forEach {
                varPs["\($0.1.name).\($0.0.name)"] = KripkeStateProperty(
                    type: .Compound($0.0.currentRecord),
                    value: $0.0
                )
            }
        }
        return World(
            externalVariables: lastWorld.externalVariables <| ps,
            variables: lastWorld.variables <| varPs
        )
    }

    private func clone(
        tokens: [(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)],
        andAssignExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        withExternalCounts externalCounts: [Machine: (Int, Int)],
        andLastRecords lastRecords: [KripkeStatePropertyList]
    ) -> [(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)] {
        return tokens.enumerated().map { (offset: Int, element: (fsm: AnyScheduleableFiniteStateMachine, machine: Machine)) -> (AnyScheduleableFiniteStateMachine, Machine) in
            var clone = element.fsm.clone()
            clone.update(fromDictionary: self.fetchValues(fromList: lastRecords[offset]))
            guard let (externalIndex, count) = externalCounts[element.machine] else {
                return (clone, element.machine)
            }
            var j = 0
            for i in externalIndex..<(externalIndex + count) {
                clone.externalVariables[j].val = externals[i].0.val
                j += 1
            }
            return (clone, element.machine)
        }
    }

}

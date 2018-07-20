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
import Scheduling
import MachineStructure

import Foundation

//swiftlint:disable opening_brace
//swiftlint:disable file_length
//swiftlint:disable cyclomatic_complexity

//swiftlint:disable:next type_body_length
public final class MachineKripkeStructureGenerator<
    Cloner: AggregateClonerProtocol,
    Detector: CycleDetector,
    Extractor: ExternalsSpinnerDataExtractorType,
    Factory: AggregateVerificationJobFactoryProtocol,
    Constructor: MultipleExternalsSpinnerConstructorType,
    StateGenerator: KripkeStateGeneratorProtocol,
    Tokenizer: SchedulerTokenizer
>: KripkeStructureGenerator where
    Detector.Element == KripkeStatePropertyList,
    Tokenizer.Object == Machine,
    Tokenizer.SchedulerToken == AnyScheduleableFiniteStateMachine
{

    private typealias ExternalsData = (
        externalVariables: AnySnapshotController,
        defaultValues: KripkeStatePropertyList,
        spinners: [String: (Any) -> Any?]
    )

    private struct Job {

        let initial: Bool

        let cache: Detector.Data

        let tokens: [[(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)]]

        let executing: Int

        let lastState: KripkeState?

        let lastRecords: [[KripkeStatePropertyList]]

    }

    private let cloner: Cloner

    private let cycleDetector: Detector

    private let extractor: Extractor

    private let factory: Factory

    private let stateGenerator: StateGenerator

    private let machines: [Machine]

    private let spinnerConstructor: Constructor

    private let tokenizer: Tokenizer

    public init(
        cloner: Cloner,
        cycleDetector: Detector,
        extractor: Extractor,
        factory: Factory,
        machines: [Machine],
        spinnerConstructor: Constructor,
        stateGenerator: StateGenerator,
        tokenizer: Tokenizer
    ) {
        self.cloner = cloner
        self.cycleDetector = cycleDetector
        self.extractor = extractor
        self.factory = factory
        self.machines = machines
        self.spinnerConstructor = spinnerConstructor
        self.stateGenerator = stateGenerator
        self.tokenizer = tokenizer
    }

    //swiftlint:disable:next function_body_length
    public func generate() -> KripkeStructure {
        var initialStates: [KripkeState] = []
        var states: [KripkeStatePropertyList: KripkeState] = [:]
        states.reserveCapacity(500000)
        // Create spinner.
        let machines = self.fetchUniqueMachines(fromMachines: self.machines)
        guard false == machines.isEmpty else {
            return KripkeStructure(states: [:])
        }
        let externalVariablesCache = self.makeExternalsData(forMachines: machines)
        // Create initial jobs.
        let tokens = self.tokenizer.separate(self.machines)
        var jobs = [MachineKripkeStructureGenerator.Job(
            initial: true,
            cache: self.cycleDetector.initialData,
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { $0.0.currentRecord } }
        )]
        // Loop until we run out of jobs.
        while false == jobs.isEmpty {
            print(jobs.count)
            let job = jobs.removeFirst()
            var spinningExternals: [String: ExternalsData] = [:]
            for (fsm, machine) in job.tokens[job.executing] {
                let key = machine.name + "." + fsm.name
                for external in fsm.externalVariables {
                    spinningExternals[external.name] = externalVariablesCache[key]?[external.name]
                }
            }
            // Execute the tokens for the current job for all variations of external variables.
            let spinner = self.spinnerConstructor.makeSpinner(forExternals: spinningExternals.map { $1 })
            while let externals = spinner() {
                // Clone all fsms.
                // swiftlint:disable:next line_length
                let clones = job.tokens.enumerated().map { (arg: (offset: Int, element: [(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)])) in
                    Array(self.cloner.clone(
                        jobs: self.factory.make(
                            tokens: arg.element,
                            externalVariables: externals
                        ),
                        withLastRecords: job.lastRecords[arg.offset]
                    ))
                }
                // Create a `KripkeState` for each ringlet executing in each fsm.
                let tempStates = execute(
                    clones: clones,
                    executing: job.executing,
                    andExternals: externals,
                    andLastState: job.lastState
                )
                if true == job.initial {
                    tempStates.first.map { initialStates.append($0) }
                }
                guard let lastTempState = tempStates.last else {
                    continue
                }
                // Append the states to the states array if these are starting states.
                var added: Bool = false
                tempStates.forEach {
                    let state = $0
                    guard let existingState = states[state.properties] else {
                        states[state.properties] = state
                        added = true
                        return
                    }
                    let oldCount = existingState.effects.count
                    existingState.effects.formUnion(state.effects)
                    if false == added {
                        added = oldCount < existingState.effects.count
                    }
                }
                if false == added {
                    continue
                }
                // Create a new job from the clones.
                let executing = (job.executing + 1) % clones.count
                jobs.append(MachineKripkeStructureGenerator.Job(
                    initial: false,
                    cache: job.cache,
                    tokens: clones,
                    executing: executing,
                    lastState: states[lastTempState.properties] ?? lastTempState,
                    lastRecords: clones.map { $0.map { $0.0.currentRecord } }
                ))
            }
        }
        print("total states: \(states.count)")
        return KripkeStructure(initialStates: initialStates, states: states)
    }

    private func execute(
        clones: [[(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)]],
        executing: Int,
        andExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andLastState last: KripkeState?
    ) -> [KripkeState] {
        var last = last
        var offset: Int = 0
        //swiftlint:disable:next line_length
        return clones[executing].flatMap { (fsm: AnyScheduleableFiniteStateMachine, machine: Machine) -> [KripkeState] in
            if true == fsm.hasFinished {
                offset += 1
                return []
            }
            let state = fsm.currentState.name
            let preWorld = self.createWorld(
                fromExternals: externals,
                andTokens: clones,
                andLastState: last,
                andExecuting: executing,
                andExecutingToken: offset,
                withState: state,
                appendingToPC: "R"
            )
            let preState = self.stateGenerator.generateKripkeState(
                fromFSM: fsm.clone(),
                withinMachine: machine,
                withLastState: last,
                addingProperties: preWorld
            )
            fsm.next()
            let postWorld = self.createWorld(
                fromExternals: externals,
                andTokens: clones,
                andLastState: preState,
                andExecuting: executing,
                andExecutingToken: offset,
                withState: state,
                appendingToPC: "W"
            )
            let postState = self.stateGenerator.generateKripkeState(
                fromFSM: fsm.clone(),
                withinMachine: machine,
                withLastState: preState,
                addingProperties: postWorld
            )
            last = postState
            offset += 1
            return [preState, postState]
        }
    }

    private func fetchUniqueMachines(fromMachines machines: [Machine]) -> Set<Machine> {
        var uniqueMachines: Set<Machine> = []
        machines.forEach {
            uniqueMachines.insert($0)
        }
        return uniqueMachines
    }

    private func makeExternalsData(forMachines: Set<Machine>) -> [String: [String: ExternalsData]] {
        var cache: [String: [String: ExternalsData]] = [:]
        machines.forEach { machine in
            self.flattenSubmachines(machine.fsm).forEach { fsm in
                let key = machine.name + "." + fsm.name
                if nil == cache[key] {
                    cache[key] = [:]
                }
                fsm.externalVariables.forEach {
                    let (defaultValues, spinners) = self.extractor.extract(
                        externalVariables: $0
                    )
                    cache[key]?[$0.name] = (
                        externalVariables: $0,
                        defaultValues: defaultValues,
                        spinners: spinners
                    )
                }
            }
        }
        return cache
    }

    fileprivate func flattenSubmachines(_ fsm: AnyScheduleableFiniteStateMachine) -> [AnyScheduleableFiniteStateMachine] {
        return [fsm] + fsm.submachines.flatMap(self.flattenSubmachines)
    }

    private func convert(externals: [(AnySnapshotController, KripkeStatePropertyList)]) -> KripkeStatePropertyList {
        var props: KripkeStatePropertyList = [:]
        var values: [String: Any] = [:]
        externals.forEach {
            props[$0.0.name] = KripkeStateProperty(type: .Compound($0.1), value: $0.0.val)
            values[$0.0.name] = $0.0.val
        }
        return [
            "externalVariables": KripkeStateProperty(
                type: .Compound(props),
                value: values
            )
        ]
    }

    private func convert(
        tokens: [[(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)]],
        executing: Int,
        executingToken token: Int,
        withState state: String,
        appendingToPC str: String
    ) -> KripkeStatePropertyList {
        var varPs: KripkeStatePropertyList = [:]
        tokens.forEach {
            $0.forEach {
                varPs["\($0.1.name).\($0.0.name)"] = KripkeStateProperty(
                    type: .Compound($0.0.currentRecord),
                    value: $0.0
                )
            }
        }
        varPs["pc"] = KripkeStateProperty(
            type: .String,
            value: self.createPC(ofToken: tokens[executing][token], withState: state, appending: str)
        )
        return varPs
    }

    //swiftlint:disable:next function_parameter_count
    private func createWorld(
        fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andTokens tokens: [[(fsm: AnyScheduleableFiniteStateMachine, machine: Machine)]],
        andLastState lastState: KripkeState?,
        andExecuting executing: Int,
        andExecutingToken token: Int,
        withState state: String,
        appendingToPC str: String
    ) -> KripkeStatePropertyList {
        let externalVariables = self.convert(externals: externals)
        let varPs = self.convert(
            tokens: tokens,
            executing: executing,
            executingToken: token,
            withState: state,
            appendingToPC: str
        )
        return (lastState?.properties ?? [:]) <| varPs <| externalVariables
    }

    private func createPC(
        ofToken token: (fsm: AnyScheduleableFiniteStateMachine, machine: Machine),
        withState state: String,
        appending str: String
    ) -> String {
        return "\(token.machine.name).\(token.fsm.name).\(state).\(str)"
    }

}

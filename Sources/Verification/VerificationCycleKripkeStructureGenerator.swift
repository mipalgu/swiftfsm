/*
 * VerificationCycleKripkeStructureGenerator.swift
 * Verification
 *
 * Created by Callum McColl on 10/9/18.
 * Copyright © 2018 Callum McColl. All rights reserved.
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

#if !NO_FOUNDATION
#if canImport(Foundation)
import Foundation
#endif
#endif

import KripkeStructure
import KripkeStructureViews
import FSM
import Gateways
import Scheduling
import MachineStructure
import ModelChecking
import FSMVerification
import swiftfsm
import swift_helpers
import Utilities

public final class VerificationCycleKripkeStructureGenerator<
    Cloner: AggregateClonerProtocol,
    Detector: CycleDetector,
    SpinnerConstructor: MultipleExternalsSpinnerConstructorType
>: LazyKripkeStructureGenerator where Detector.Element == KripkeStatePropertyList
{
    
    fileprivate let tokens: [[VerificationToken]]
    fileprivate let cloner: Cloner
    fileprivate let cycleDetector: Detector
    fileprivate let executer: VerificationCycleExecuter
    fileprivate let spinnerConstructor: SpinnerConstructor
    fileprivate let worldCreator: WorldCreator
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    
    public weak var delegate: LazyKripkeStructureGeneratorDelegate?
    
    fileprivate var tokensLookup: [FSM_ID: VerificationToken] = [:]
    
    public init(
        tokens: [[VerificationToken]],
        cloner: Cloner,
        cycleDetector: Detector,
        executer: VerificationCycleExecuter = VerificationCycleExecuter(),
        spinnerConstructor: SpinnerConstructor,
        worldCreator: WorldCreator = WorldCreator()
    ) {
        self.tokens = tokens
        self.cloner = cloner
        self.cycleDetector = cycleDetector
        self.executer = executer
        self.spinnerConstructor = spinnerConstructor
        self.worldCreator = worldCreator
        self.tokens.forEach {
            $0.forEach {
                guard let data = $0.data else {
                    return
                }
                self.tokensLookup[data.id] = $0
            }
        }
    }
    
    public func generate<Gateway: ModifiableFSMGateway, View: KripkeStructureView>(usingGateway gateway: Gateway, andView view: View, storingResultsFor resultID: FSM_ID?) -> SortedCollection<(UInt, Any?)>? where View.State == KripkeState {
        var jobs = self.createInitialJobs(fromTokens: self.tokens)
        view.reset()
        let defaultExternals = self.createExternals(fromTokens: self.tokens)
        var globalDetectorCache = self.cycleDetector.initialData
        var foundCycle = false
        var results: SortedCollection<(UInt, Any?)> = SortedCollection(comparator: AnyComparator {
            if $0.0 < $1.0 {
                return .orderedAscending
            }
            if $0.0 > $1.0 {
                return .orderedDescending
            }
            return .orderedSame
        })
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            // Skip this job if all tokens are .skip tokens.
            if nil == job.tokens[job.executing].first(where: { nil != $0.data }) {
                jobs.append(Job(
                    initial: job.initial,
                    cache: job.cache,
                    tokens: job.tokens,
                    executing: (job.executing + 1) % job.tokens.count,
                    lastState: job.lastState,
                    lastRecords: job.lastRecords,
                    runs: job.runs,
                    callStack: job.callStack
                ))
                continue
            }
            // Create results for all parameterised machines that are finished.
            var allResults: [FSM_ID: LazyMapCollection<SortedCollectionSlice<(UInt, Any?)>, Any?>] = [:]
            allResults.reserveCapacity(job.callStack.count)
            for (id, calls) in job.callStack {
                guard let callData = calls.last else {
                    continue
                }
                guard let callResults = self.delegate?.resultsForCall(self, call: callData, withGateway: gateway) else {
                    fatalError("Unable to fetch results for call: \(callData)")
                }
                allResults[id] = callResults.find((callData.runs, nil)).lazy.map { $0.1 }
            }
            // Create spinner for results.
            let resultsSpinner = self.createSpinner(forValues: allResults)
            while let parameterisedResults = resultsSpinner() {
                // Create a spinner for the external variables.
                let externalsData = self.fetchUniqueExternalsData(fromTokens: [job.tokens[job.executing]])
                let spinner = self.spinnerConstructor.makeSpinner(forExternals: externalsData)
                // Generate kirpke states for each variation of external variables.
                while let externals = spinner() {
                    let externals = nil == job.lastState ? self.mergeExternals(externals, with: defaultExternals) : externals
                    guard let firstData = job.tokens[job.executing].first(where: { nil != $0.data })?.data else {
                        break
                    }
                    // Assign results to promises.
                    for (id, calls) in job.callStack {
                        guard let callData = calls.last else {
                            continue
                        }
                        callData.promiseData.result = parameterisedResults[id]
                    }
                    // Check for cycles.
                    let world = self.worldCreator.createWorld(
                        fromExternals: externals,
                        andTokens: job.tokens,
                        andLastState: job.lastState,
                        andExecuting: job.executing,
                        andExecutingToken: 0,
                        withState: firstData.fsm.currentState.name,
                        usingCallStack: job.callStack,
                        worldType: .beforeExecution
                    )
                    let (inLocalCycle, newCache) = self.cycleDetector.inCycle(data: job.cache, element: world)
                    foundCycle = foundCycle || inLocalCycle
                    let (inGlobalCycle, newGlobalCache) = self.cycleDetector.inCycle(data: globalDetectorCache, element: world)
                    globalDetectorCache = newGlobalCache
                    if true == inGlobalCycle {
                        job.lastState?.effects.insert(world)
                        continue
                    }
                    // Clone all fsms.
                    let clones = job.tokens.enumerated().map {
                        Array(self.cloner.clone(jobs: $1, withLastRecords: job.lastRecords[$0]))
                    }
                    // Clone callStack
                    let callStack = job.callStack.mapValues { $0.map { CallData(id: $0.id, fsm: $0.fsm.clone(), fullyQualifiedName: $0.fullyQualifiedName, parameters: $0.parameters, promiseData: $0.promiseData, inPlace: $0.inPlace, runs: $0.runs, tokens: $0.tokens, view: $0.view) } }
                    // Execute and generate kripke states.
                    let runs = self.executer.execute(
                        tokens: clones,
                        executing: job.executing,
                        withExternals: externals,
                        andLastState: job.lastState,
                        isInitial: job.initial,
                        usingView: view,
                        andCallStack: callStack,
                        withDelegate: self
                    )
                    // Create jobs for each different 'run' possible.
                    for (lastState, newTokens, newCallStack) in runs {
                        // Do not generate more jobs if we do not have a last state - means that nothing was executed, should never happen.
                        guard let lastNewState = lastState else {
                            continue
                        }
                        // Add the lastNewState as a finishing state if all fsms have finished -- don't bother to generate more jobs.
                        if nil == newTokens.first(where: { nil != $0.first { !($0.data?.fsm.hasFinished ?? true) } }) {
                            if false == foundCycle {
                                for tokens in newTokens {
                                    for token in tokens {
                                        guard let data = token.data else {
                                            continue
                                        }
                                        if data.id == resultID {
                                            //results.insert((job.runs, data.fsm.resultsContainer.results))
                                        }
                                    }
                                }
                                results.insert((job.runs, nil))
                            }
                            view.commit(state: lastNewState, isInitial: false)
                            continue
                        }
                        let newExecutingIndex = (job.executing + 1) % newTokens.count
                        // Create a new job from the clones.
                        jobs.append(Job(
                            initial: false,
                            cache: newCache,
                            tokens: newTokens,
                            executing: newExecutingIndex,
                            lastState: lastNewState,
                            lastRecords: newTokens.map { $0.map {
                                ($0.data?.fsm.asScheduleableFiniteStateMachine.base).map(self.recorder.takeRecord) ?? KripkeStatePropertyList()
                            } },
                            runs: 0 == newExecutingIndex ? job.runs + 1 : job.runs,
                            callStack: newCallStack
                        ))
                    }
                }
            }
            _ = job.lastState.map { view.commit(state: $0, isInitial: false) }
        }
        view.finish()
        if true == foundCycle {
            return nil
        }
        return results
        /*print("number of initial states: \(initialStates.value.count)")
        print("number of state: \(states.value.count)")
        print("number of transitions: \(states.value.reduce(0) { $0 + $1.1.effects.count })")
        return KripkeStructure(initialStates: Array(initialStates.value.lazy.map { $1 }), states: states.value)*/
    }
    
    fileprivate func mergeExternals(_ externals: [(AnySnapshotController, KripkeStatePropertyList)], with dict: [String: (AnySnapshotController, KripkeStatePropertyList)]) -> [(AnySnapshotController, KripkeStatePropertyList)] {
        var dict = dict
        for (external, ps) in externals {
            dict[external.name] = (external, ps)
        }
        return Array(dict.values)
    }
    
    fileprivate func createExternals(fromTokens tokens: [[VerificationToken]]) -> [String: (AnySnapshotController, KripkeStatePropertyList)] {
        let allExternalsData = self.fetchUniqueExternalsData(fromTokens: tokens)
        var d = [String: (AnySnapshotController, KripkeStatePropertyList)](minimumCapacity: allExternalsData.count)
        allExternalsData.forEach {
            d[$0.externalVariables.name] = ($0.externalVariables, $0.defaultValues)
        }
        return d
    }
    
    fileprivate func createInitialJobs(fromTokens tokens: [[VerificationToken]]) -> [Job] {
        return [Job(
            initial: true,
            cache: self.cycleDetector.initialData,
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { ($0.data?.fsm.asScheduleableFiniteStateMachine.base).map(self.recorder.takeRecord) ?? KripkeStatePropertyList() } },
            runs: 0,
            callStack: [:]
        )]
    }
    
    fileprivate func fetchUniqueExternalsData(fromTokens tokens: [[VerificationToken]]) -> [ExternalVariablesVerificationData] {
        var hashTable: Set<String> = []
        var externals: [ExternalVariablesVerificationData] = []
        for tokens in tokens {
            tokens.forEach { ($0.data?.externalVariables ?? []).forEach {
                if hashTable.contains($0.externalVariables.name) {
                    return
                }
                externals.append($0)
                hashTable.insert($0.externalVariables.name)
            } }
        }
        return externals
    }
    
    fileprivate func createSpinner<Key, Value, C: Collection>(forValues values: [Key: C]) -> () -> [Key: Value]? where C.Iterator.Element == Value {
        func newSpinner(_ values: C) -> () -> Value? {
            var i = values.startIndex
            return {
                guard i != values.endIndex else {
                    return nil
                }
                defer { i = values.index(after: i) }
                return values[i]
            }
        }
        var spinners = values.mapValues(newSpinner)
        guard var currentValues: [Key: Value] = spinners.failMap({
            if let value = $1() {
                return ($0, value)
            }
            return nil
        }).map({ Dictionary(uniqueKeysWithValues: $0) })
        else {
            return { nil }
        }
        func handleSpinner(index: Dictionary<Key, () -> Value?>.Index) -> [Key: Value]? {
            if index == spinners.endIndex {
                return nil
            }
            let (key, spinner) = spinners[index]
            if let value = spinner() {
                currentValues[key] = value
                return currentValues
            }
            spinners[key] = newSpinner(values[key]!)
            guard let value = spinners[index].value() else {
                return nil
            }
            currentValues[key] = value
            return handleSpinner(index: spinners.index(after: index))
        }
        var first = true
        return {
            defer { first = false }
            return first ? currentValues : handleSpinner(index: spinners.startIndex)
        }
    }
    
    fileprivate struct Job {
        
        let initial: Bool
        
        let cache: Detector.Data
        
        let tokens: [[VerificationToken]]
        
        let executing: Int
        
        let lastState: KripkeState?
        
        let lastRecords: [[KripkeStatePropertyList]]
        
        let runs: UInt
        
        let callStack: [FSM_ID: [CallData]]
        
    }
    
}

extension VerificationCycleKripkeStructureGenerator: VerificationTokenExecuterDelegate {
    
    public func results<Gateway: ModifiableFSMGateway>(of callData: CallData, caller: FSM_ID, withGateway gateway: Gateway) -> [(UInt, Any?)] {
        guard let results = self.delegate?.resultsForCall(self, call: callData, withGateway: gateway) else {
            fatalError("Unable to generate kripke structure for call \(callData)")
        }
        return Array(results)
    }
    
    public func scheduleInfo(of id: FSM_ID, caller: FSM_ID) -> ([[VerificationToken]], AnyKripkeStructureView<KripkeState>) {
        guard let callerToken = self.tokensLookup[caller], let callerData = callerToken.data else {
            fatalError("Unable to fetch caller token from caller id.")
        }
        guard let (_, tokens, view) = callerData.callableMachines[id] else {
            fatalError("Unable to fetch schedule info of '\(id)'")
        }
        return (tokens, view)
    }
    
    public func shouldInclude(call callData: CallData, forCaller caller: FSM_ID) -> Bool {
        guard let callerToken = self.tokensLookup[caller], let callerData = callerToken.data else {
            return false
        }
        return nil != callerData.callableMachines[callData.id]
    }
    
    public func shouldInline(call callData: CallData, caller: FSM_ID) -> Bool {
        return callData.id == caller
    }
    
}

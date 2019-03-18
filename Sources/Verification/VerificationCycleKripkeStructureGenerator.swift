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
    fileprivate let fetcher = ExternalVariablesFetcher()
    
    public weak var delegate: LazyKripkeStructureGeneratorDelegate?
    
    fileprivate var tokensLookup: [FSM_ID: VerificationToken] = [:]
    fileprivate var view: AnyKripkeStructureView<KripkeState>!
    
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
    
    public func generate<Gateway: VerifiableGateway, View: KripkeStructureView>(usingGateway gateway: Gateway, andView view: View, storingResultsFor resultID: FSM_ID?) -> SortedCollection<(UInt, Any?)>? where View.State == KripkeState {
        self.view = AnyKripkeStructureView(view)
        let initialGatewayData = gateway.gatewayData
        var jobs = self.createInitialJobs(fromTokens: self.tokens, andGateway: gateway)
        let defaultExternals = self.fetcher.createExternals(fromTokens: self.tokens)
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
        var parameterisedMachines: [FSM_ID: ParameterisedMachineData] = [:]
        self.tokens.forEach { $0.forEach {
            guard let tokenData = $0.data else {
                return
            }
            for (id, data) in tokenData.parameterisedMachines {
                parameterisedMachines[id] = data
            }
        }}
        var counter = 0
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
                    callStack: job.callStack,
                    results: job.results,
                    foundResult: job.foundResult,
                    gatewayData: job.gatewayData
                ))
                continue
            }
            // Create results for all parameterised machines that are finished.
            let (allResults, handledAllResults) = self.createAllResults(forJob: job, withGateway: gateway, andInitialGatewayData: initialGatewayData)
            // Create spinner for results.
            let resultsSpinner = self.fetcher.createSpinner(forValues: allResults)
            while let parameterisedResults = resultsSpinner() {
                // Create a spinner for the external variables.
                let externalsData = self.fetcher.fetchUniqueExternalsData(fromTokens: [job.tokens[job.executing]])
                let spinner = self.spinnerConstructor.makeSpinner(forExternals: externalsData)
                // Generate kirpke states for each variation of external variables.
                while let externals = spinner() {
                    let externals = nil == job.lastState ? self.fetcher.mergeExternals(externals, with: defaultExternals) : externals
                    guard let firstData = job.tokens[job.executing].first(where: { nil != $0.data })?.data else {
                        break
                    }
                    // Assign results to promises.
                    for (id, calls) in job.callStack {
                        guard let callData = calls.last else {
                            continue
                        }
                        guard let result: Any? = parameterisedResults[id] else {
                            callData.promiseData.hasFinished = false
                            continue
                        }
                        callData.promiseData.hasFinished = result != nil
                        callData.promiseData.result = result
                    }
                    counter += 1
                    // Check for cycles.
                    let world = self.worldCreator.createWorld(
                        fromExternals: externals,
                        andParameterisedMachines: parameterisedMachines,
                        andTokens: job.tokens,
                        andLastState: job.lastState,
                        andExecuting: job.executing,
                        andExecutingToken: 0,
                        withState: firstData.fsm.currentState.name,
                        usingCallStack: job.callStack,
                        worldType: .beforeExecution
                    )
                    var newCache: Detector.Data = job.cache
                    foundCycle = foundCycle || self.cycleDetector.inCycle(data: &newCache, element: world)
                    if true == self.cycleDetector.inCycle(data: &globalDetectorCache, element: world) {
                        if nil == resultID {
                            job.lastState?.effects.insert(world)
                            continue
                        } else if foundCycle && handledAllResults {
                            return nil
                        }
                    }
                    // Clone all fsms.
                    let clones = job.tokens.enumerated().map { Array(self.cloner.clone(jobs: $1, withLastRecords: job.lastRecords[$0])) }
                    // Clone callStack
                    let callStack = job.callStack.mapValues { $0.map { CallData(data: $0.data, parameters: $0.parameters, promiseData: $0.promiseData, runs: $0.runs) } }
                    gateway.gatewayData = job.gatewayData as! Gateway.GatewayData
                    // Execute and generate kripke states.
                    let runs = self.executer.execute(
                        tokens: clones,
                        executing: job.executing,
                        withExternals: externals,
                        andParameterisedMachines: parameterisedMachines,
                        andGateway: gateway,
                        andLastState: job.lastState,
                        isInitial: job.initial,
                        usingView: self.view,
                        andCallStack: callStack,
                        andPreviousResults: job.results,
                        withDelegate: self
                    )
                    // Create jobs for each different 'run' possible.
                    for (lastState, newTokens, newCallStack, newGatewayData, newResults) in runs {
                        // Do not generate more jobs if we do not have a last state -- means that nothing was executed, should never happen.
                        guard let lastNewState = lastState else {
                            continue
                        }
                        var allFinished = true // Are all fsms finished?
                        var foundResult = job.foundResult
                        for tokens in newTokens {
                            for token in tokens {
                                guard let data = token.data else {
                                    continue
                                }
                                // Add any results for the finished fsms.
                                if data.id == resultID && false == job.foundResult && data.fsm.hasFinished {
                                    results.insert((job.runs, data.fsm.resultContainer?.result))
                                    foundResult = true // Remember that we have found this result. Stops us adding this result more than once.
                                }
                                allFinished = allFinished && (data.fsm.hasFinished || data.fsm.isSuspended)
                            }
                        }
                        // Add the lastNewState as a finishing state -- don't generate more jobs as all fsms have finished.
                        if true == allFinished {
                            self.view.commit(state: lastNewState, isInitial: false)
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
                            callStack: newCallStack,
                            results: newResults,
                            foundResult: foundResult,
                            gatewayData: newGatewayData
                        ))
                    }
                }
            }
            _ = job.lastState.map { self.view.commit(state: $0, isInitial: false) }
        }
        if true == foundCycle {
            return nil
        }
        return results
        /*print("number of initial states: \(initialStates.value.count)")
        print("number of state: \(states.value.count)")
        print("number of transitions: \(states.value.reduce(0) { $0 + $1.1.effects.count })")
        return KripkeStructure(initialStates: Array(initialStates.value.lazy.map { $1 }), states: states.value)*/
    }
    
    fileprivate func createAllResults<Gateway: VerifiableGateway>(forJob job: Job, withGateway gateway: Gateway, andInitialGatewayData initialGatewayData: Gateway.GatewayData) -> ([FSM_ID: LazyMapCollection<SortedCollectionSlice<(UInt, Any?)>, Any?>], Bool) {
        var allResults: [FSM_ID: LazyMapCollection<SortedCollectionSlice<(UInt, Any?)>, Any?>] = [:]
        allResults.reserveCapacity(job.callStack.count)
        var handledAllResults = true
        for (id, calls) in job.callStack {
            guard nil == job.results[id], let callData = calls.last else {
                continue
            }
            gateway.gatewayData = initialGatewayData
            guard let callResults = self.delegate?.resultsForCall(self, call: callData, withGateway: gateway) else {
                fatalError("Unable to fetch results for call: \(callData)")
            }
            allResults[id] = callResults.find((callData.runs, nil)).lazy.map { $0.1 }
            handledAllResults = handledAllResults && callData.runs > (callResults.last?.0 ?? 0)
        }
        return (allResults, handledAllResults)
    }
    
    fileprivate func createInitialJobs<Gateway: VerifiableGateway>(fromTokens tokens: [[VerificationToken]], andGateway gateway: Gateway) -> [Job] {
        return [Job(
            initial: true,
            cache: self.cycleDetector.initialData,
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { ($0.data?.fsm.asScheduleableFiniteStateMachine.base).map(self.recorder.takeRecord) ?? KripkeStatePropertyList() } },
            runs: 0,
            callStack: [:],
            results: [:],
            foundResult: false,
            gatewayData: gateway.gatewayData
        )]
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
        
        let results: [FSM_ID: Any?]
        
        let foundResult: Bool
        
        let gatewayData: Any // Fix this type later.
        
    }
    
}

extension VerificationCycleKripkeStructureGenerator: VerificationTokenExecuterDelegate {
    
    public func scheduleInfo(of id: FSM_ID, caller: FSM_ID, inGateway gateway: ModifiableFSMGateway) -> ParameterisedMachineData {
        guard let callerToken = self.tokensLookup[caller], let callerData = callerToken.data else {
            fatalError("Unable to fetch caller token from caller id.")
        }
        if callerData.id == id {
            let fsm = gateway.fsms[id]
            guard let parameterisedFSM = fsm?.asParameterisedFiniteStateMachine else {
                fatalError("Cannot call self if self is not a parameterised machine.")
            }
            guard let fullyQualifiedName = gateway.ids.first(where: { $0.value == id })?.key else {
                fatalError("Unable to fetch fullyQualifiedName of self.")
            }
            return ParameterisedMachineData(
                id: id,
                fsm: parameterisedFSM,
                fullyQualifiedName: fullyQualifiedName,
                parameters: Set(self.recorder.takeRecord(of: parameterisedFSM.parameters).propertiesDictionary.keys),
                inPlace: true,
                tokens: self.tokens,
                view: self.view
            )
        }
        guard let data = callerData.parameterisedMachines[id] else {
            fatalError("FSM with id '\(id)' is not callable by this FSM.")
        }
        return data
    }
    
    public func shouldInclude(call callData: CallData, forCaller caller: FSM_ID) -> Bool {
        guard let callerToken = self.tokensLookup[caller], let callerData = callerToken.data else {
            return false
        }
        return nil != callerData.parameterisedMachines[callData.id]
    }
    
    public func shouldInline(call callData: CallData, caller: FSM_ID) -> Bool {
        return callData.id == caller
    }
    
}

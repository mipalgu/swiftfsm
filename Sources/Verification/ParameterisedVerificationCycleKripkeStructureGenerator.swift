/*
 * ParameterisedVerificationCycleKripkeStructureGenerator.swift
 * Verification
 *
 * Created by Callum McColl on 18/3/19.
 * Copyright © 2019 Callum McColl. All rights reserved.
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
import KripkeStructureViews
import Gateways
import ModelChecking
import swiftfsm
import swift_helpers

public final class ParameterisedVerificationCycleKripkeStructureGenerator<Detector: CycleDetector>: LazyKripkeStructureGenerator where Detector.Element == KripkeStatePropertyList {
    
    fileprivate let cycleDetector: Detector
    fileprivate let tokens: [[VerificationToken]]
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    fileprivate let generator = VerificationCycleKripkeStructureGeneratorFactory().make()
    fileprivate let fetcher: ExternalVariablesFetcher = ExternalVariablesFetcher()
    
    fileprivate lazy var tokensLookup: [FSM_ID: VerificationToken] = {
        var dict: [FSM_ID: VerificationToken] = [:]
        tokens.forEach { $0.forEach {
            guard let data = $0.data else {
                return
            }
            dict[data.id] = $0
        }}
        return dict
    }()
    
    fileprivate var view: AnyKripkeStructureView<KripkeState>!
    
    public weak var delegate: LazyKripkeStructureGeneratorDelegate?
    
    public init(cycleDetector: Detector, tokens: [[VerificationToken]]) {
        self.cycleDetector = cycleDetector
        self.tokens = tokens
    }
    
    public func generate<Gateway: VerifiableGateway, View: KripkeStructureView>(
        usingGateway gateway: Gateway,
        andView view: View,
        storingResultsFor resultID: FSM_ID?
    ) -> SortedCollection<(UInt, Any?)>? where View.State == KripkeState {
        self.view = AnyKripkeStructureView(view)
        let initialGatewayData = gateway.gatewayData
        var jobs = self.createInitialJobs(fromTokens: self.tokens, andGateway: gateway)
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
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            // Skip this job if all tokens are .skip tokens.
            if nil == job.tokens[job.executing].first(where: { nil != $0.data }) {
                var newJob = job
                newJob.executing = (job.executing + 1) % job.tokens.count
                jobs.append(newJob)
                continue
            }
            // Create results for all parameterised machines that are finished.
            let (allResults, handledAllResults) = self.createAllResults(forJob: job, withGateway: gateway, andInitialGatewayData: initialGatewayData)
            // Create spinner for results.
            let resultsSpinner = self.createSpinner(forValues: allResults)
            while let parameterisedResults = resultsSpinner() {
                gateway.gatewayData = job.gatewayData as! Gateway.GatewayData
                let runs = self.generator.generate(
                    fromState: job,
                    usingCycleDetector: self.cycleDetector,
                    usingGateway: gateway,
                    storingKripkeStructureIn: view,
                    checkingForCyclesWith: &globalDetectorCache,
                    callingParameterisedMachines: parameterisedMachines,
                    withParameterisedResults: parameterisedResults,
                    storingResultsFor: resultID,
                    handledAllResults: handledAllResults,
                    tokenExecuterDelegate: self
                )
                defer { gateway.removeFinished() }
                for var run in runs {
                    // Do not generate more jobs if we do not have a last state -- means that nothing was executed, should never happen.
                    guard let lastNewState = run.lastState else {
                        continue
                    }
                    var allFinished = true // Are all fsms finished?
                    var foundResult = run.foundResult
                    for tokens in run.tokens {
                        for token in tokens {
                            guard let data = token.data else {
                                continue
                            }
                            // Add any results for the finished fsms.
                            if data.id == resultID && false == run.foundResult && data.fsm.hasFinished {
                                results.insert((run.runs, data.fsm.resultContainer?.result))
                                foundResult = true // Remember that we have found this result. Stops us adding this result more than once.
                            }
                            allFinished = allFinished && (data.fsm.hasFinished || data.fsm.isSuspended)
                        }
                    }
                    // Add the lastNewState as a finishing state -- don't generate more jobs as all fsms have finished.
                    if true == allFinished {
                        view.commit(state: lastNewState, isInitial: false)
                        continue
                    }
                    let newExecutingIndex = (run.executing + 1) % run.tokens.count
                    foundCycle = foundCycle || run.foundCycle
                    // Create a new job from the clones.
                    run.executing = newExecutingIndex
                    run.foundResult = foundResult
                    run.initial = false
                    jobs.append(run)
                 }
            }
            _ = job.lastState.map { view.commit(state: $0, isInitial: false) }
        }
        if true == foundCycle {
            return nil
        }
        return results
    }
    
    fileprivate func createAllResults<Gateway: VerifiableGateway>(forJob job: VerificationState<Detector.Data>, withGateway gateway: Gateway, andInitialGatewayData initialGatewayData: Gateway.GatewayData) -> ([FSM_ID: LazyMapCollection<SortedCollectionSlice<(UInt, Any?)>, Any?>], Bool) {
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
    
    fileprivate func createInitialJobs<Gateway: VerifiableGateway>(fromTokens tokens: [[VerificationToken]], andGateway gateway: Gateway) -> [VerificationState<Detector.Data>] {
        return [VerificationState(
                initial: true,
                cycleCache: self.cycleDetector.initialData,
                foundCycle: false,
                tokens: tokens,
                executing: 0,
                lastState: nil,
                lastRecords: tokens.map { $0.map { ($0.data?.fsm.asScheduleableFiniteStateMachine.base).map(self.recorder.takeRecord) ?? KripkeStatePropertyList() } },
                runs: 0,
                callStack: [:],
                results: [:],
                foundResult: false,
                gatewayData: gateway.gatewayData
            )
        ]
    }
    
    public func createSpinner<Key, Value, C: Collection>(forValues values: [Key: C]) -> () -> [Key: Value]? where C.Iterator.Element == Value {
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
    
}

extension ParameterisedVerificationCycleKripkeStructureGenerator: VerificationTokenExecuterDelegate {
    
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

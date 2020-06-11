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
        // Create the initial starting jobs.
        var jobs = self.createInitialJobs(fromTokens: self.tokens, andGateway: gateway)
        var globalDetectorCache = self.cycleDetector.initialData // The cycle detectors data which we keep mutating.
        var foundCycle = false // Have we found a cycle?
        // Stores any results for the fsm with id `resultID`.
        // The results are sorted by the run count, in other words, how many
        // schedule cycles it takes to generate the result.
        // These results will be returned once the kripke structure has been generated.
        var results: SortedCollection<(UInt, Any?)> = SortedCollection(comparator: AnyComparator {
            if $0.0 < $1.0 {
                return .orderedAscending
            }
            if $0.0 > $1.0 {
                return .orderedDescending
            }
            return .orderedSame
        })
        // Remember all possible parameterised machines that could be called, as
        // well as the `ParameterisedMachineData` associated with them.
        var parameterisedMachines: [FSM_ID: ParameterisedMachineData] = [:]
        self.tokens.forEach { $0.forEach {
            guard let tokenData = $0.data else {
                return
            }
            for (id, data) in tokenData.parameterisedMachines {
                parameterisedMachines[id] = data
            }
        }}
        // Generate kripke states until we have no jobs left.
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            // Skip this job if all tokens are .skip tokens.
            if nil == job.tokens[job.executing].first(where: { nil != $0.data }) {
                var newJob = job
                newJob.executing = (job.executing + 1) % job.tokens.count
                jobs.append(newJob)
                continue
            }
            gateway.gatewayData = job.gatewayData
            // Create results for all parameterised machines that are finished.
            let (allResults, handledAllResults) = self.createAllResults(forJob: job, withGateway: gateway)
            // Create spinner for results from called parameterised machines.
            let resultsSpinner = self.createSpinner(forValues: allResults)
            // Generate kripke states for each variation of results from called parameterised machines.
            while let parameterisedResults = resultsSpinner() {
                // Generate kripke states.
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
                // Process each run and create new jobs from it.
                for var run in runs {
                    // Do not generate more jobs if we do not have a last state,
                    // means that nothing was executed, should never happen.
                    guard let lastNewState = run.lastState else {
                        continue
                    }
                    var allFinished = true // Are all fsms finished?
                    var foundResult = run.foundResult // Did the fsm with id `resultID` return a result?
                    for tokens in run.tokens {
                        for token in tokens {
                            guard let data = token.data else {
                                continue
                            }
                            // Add any results for the finished fsms.
                            if data.id == resultID && false == run.foundResult && data.fsm.hasFinished {
                                results.insert((run.runs, data.fsm.resultContainer?.result))
                                // Remember that we have found this result.
                                // Stops us adding this result more than once.
                                foundResult = true
                            }
                            allFinished = allFinished && (data.fsm.hasFinished || data.fsm.isSuspended)
                        }
                    }
                    // Add the lastNewState as a finishing state,
                    // don't generate more jobs as all fsms have finished.
                    if true == allFinished {
                        view.commit(state: lastNewState, isInitial: false)
                        continue
                    }
                    let newExecutingIndex = (run.executing + 1) % run.tokens.count
                    foundCycle = foundCycle || run.foundCycle
                    // Create a new job from the run.
                    run.executing = newExecutingIndex
                    run.foundResult = foundResult
                    run.initial = false
                    jobs.append(run)
                 }
            }
            _ = job.lastState.map { view.commit(state: $0, isInitial: false) }
        }
        // Don't return any results if we have cycles.
        if true == foundCycle {
            return nil
        }
        return results
    }

    /*
     *  Fetches the results of a call to a parameterised machine.
     *
     *  - Parameter job: The job that is about to be executed. Importantly,
     *  the `callStack` of this job is used to fetch the results. The results
     *  for the parameterised machine on the top of the stack are returned.
     *
     *  - Parameter gateway: The `Gateway` containing the references to the
     *  parameterised machines.
     *
     *  - Returns: A tuple containing results and a Bool indicating
     *  whether all possible results have been fetched. This Bool could be
     *  false if there is a possibility that the caller must wait further
     *  schedule cycles for further results. The results are a dictionary
     *  mapping the `FSM_ID` of a parameterised machine to a collection of
     *  result values. These results represent the results that would be
     *  available to the caller that has been waiting for the schedule cycles
     *  count retrieved from the `CallData.runs` variable of the call.
     */
    fileprivate func createAllResults<Gateway: VerifiableGateway>(forJob job: VerificationState<Detector.Data, Gateway.GatewayData>, withGateway gateway: Gateway) -> ([FSM_ID: LazyMapCollection<SortedCollectionSlice<(UInt, Any?)>, Any?>], Bool) {
        // Setup our results collection.
        var allResults: [FSM_ID: LazyMapCollection<SortedCollectionSlice<(UInt, Any?)>, Any?>] = [:]
        allResults.reserveCapacity(job.callStack.count)
        var handledAllResults = true // Have we handled all results? Or alternatively, are there no more results to fetch after this?
        for (id, calls) in job.callStack {
            // This should never happen.
            guard nil == job.results[id], let callData = calls.last else {
                continue
            }
            // Fetch the results for this particular call.
            guard let callResults = self.delegate?.resultsForCall(self, call: callData, withGateway: gateway) else {
                fatalError("Unable to fetch results for call: \(callData)")
            }
            // Add the results to our collection and make sure to check if
            // there is a possibily for more results in the future.
            allResults[id] = callResults.find((callData.runs, nil)).lazy.map { $0.1 }
            handledAllResults = handledAllResults && callData.runs > (callResults.last?.0 ?? 0)
        }
        return (allResults, handledAllResults)
    }

    fileprivate func createInitialJobs<Gateway: VerifiableGateway>(fromTokens tokens: [[VerificationToken]], andGateway gateway: Gateway) -> [VerificationState<Detector.Data, Gateway.GatewayData>] {
        let initial: Bool
        let lastState: KripkeState?
        if nil != tokens.lazy.flatMap({ $0 }).first(where: { $0.timeData != nil }) {
            let kripkeState = KripkeState(properties: ["pc": KripkeStateProperty(type: .String, value: "initial")])
            self.view.commit(state: kripkeState, isInitial: true)
            initial = false
            lastState = kripkeState
        } else {
            initial = true
            lastState = nil
        }
        return [VerificationState(
                initial: initial,
                cycleCache: self.cycleDetector.initialData,
                foundCycle: false,
                tokens: tokens,
                executing: 0,
                lastState: lastState,
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

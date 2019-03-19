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

public final class ParameterisedVerificationCycleKripkeStructureGenerator<Detector: CycleDetector>: LazyKripkeStructureGenerator {
    
    fileprivate let cycleDetector: Detector
    fileprivate let tokens: [[VerificationToken]]
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    fileprivate let generator = VerificationCycleKripkeStructureGenerator()
    fileprivate let fetcher: ExternalVariablesFetcher = ExternalVariablesFetcher()
    
    public weak var delegate: LazyKripkeStructureGeneratorDelegate?
    
    public init(cycleDetector: Detector, tokens: [[VerificationToken]], generator: Generator) {
        self.cycleDetector = cycleDetector
        self.tokens = tokens
        self.generator = generator
    }
    
    public func generate<Gateway: VerifiableGateway, View: KripkeStructureView>(
        usingGateway gateway: Gateway,
        andView view: View,
        storingResultsFor resultID: FSM_ID?
    ) -> SortedCollection<(UInt, Any?)>? where View.State == KripkeState {
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
            let resultsSpinner = self.createSpinner(forValues: allResults)
            while let parameterisedResults = resultsSpinner() {
                let state = VerificationState<Detector.Data>(
                    initial: job.initial,
                    cycleCache: job.cache,
                    counter: counter,
                    foundCycle: foundCycle,
                    tokens: job.tokens,
                    executing: job.executing,
                    lastState: job.lastState,
                    lastRecords: job.lastRecords,
                    runs: job.runs,
                    callStack: job.callStack,
                    results: job.results,
                    foundResult: job.foundResult,
                    gatewayData: job.gatewayData
                )
                let runs = self.generator.generate(
                    fromState: state,
                    usingCycleDetector: self.cycleDetector,
                    usingGateway: gateway,
                    storingKripkeStructureIn: view,
                    checkingForCyclesWith: globalDetectorCache,
                    callingParameterisedMachines: parameterisedMachines,
                    withParameterisedResults: parameterisedResults,
                    storingResultsFor: resultID,
                    handledAllResults: handledAllResults
                )
            }
        }
        if true == foundCycle {
            return nil
        }
        return nil
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

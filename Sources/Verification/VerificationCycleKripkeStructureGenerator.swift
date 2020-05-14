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

final class VerificationCycleKripkeStructureGenerator<
    Cloner: AggregateClonerProtocol,
    SpinnerConstructor: MultipleExternalsSpinnerConstructorType
> {

    fileprivate let cloner: Cloner
    fileprivate let executer = VerificationCycleExecuter()
    fileprivate let spinnerConstructor: SpinnerConstructor
    fileprivate let worldCreator = WorldCreator()
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    fileprivate let fetcher = ExternalVariablesFetcher()

    init(cloner: Cloner, spinnerConstructor: SpinnerConstructor) {
        self.cloner = cloner
        self.spinnerConstructor = spinnerConstructor
    }

    func generate<Detector: CycleDetector, Gateway: VerifiableGateway, View: KripkeStructureView>(
        fromState state: VerificationState<Detector.Data, Gateway.GatewayData>,
        usingCycleDetector cycleDetector: Detector,
        usingGateway gateway: Gateway,
        storingKripkeStructureIn view: View,
        checkingForCyclesWith globalDetectorCache: inout Detector.Data,
        callingParameterisedMachines parameterisedMachines: [FSM_ID: ParameterisedMachineData],
        withParameterisedResults parameterisedResults: [FSM_ID: Any?],
        storingResultsFor resultID: FSM_ID?,
        handledAllResults: Bool,
        tokenExecuterDelegate: VerificationTokenExecuterDelegate
    ) -> [VerificationState<Detector.Data, Gateway.GatewayData>] where View.State == KripkeState, Detector.Element == KripkeStatePropertyList {
        // Runs contains any new verification states which result from running state.
        var runs: [VerificationState<Detector.Data, Gateway.GatewayData>] = []
        // Create a spinner for the external variables.
        let defaultExternals = self.fetcher.createExternals(fromTokens: state.tokens)
        let externalsData = self.fetcher.fetchUniqueExternalsData(fromTokens: [state.tokens[state.executing]])
        let spinner = self.spinnerConstructor.makeSpinner(forExternals: externalsData)
        // Generate kirpke states for each variation of external variables.
        while let externals = spinner() {
            var job = state
            let externals = nil == job.lastState ? self.fetcher.mergeExternals(externals, with: defaultExternals) : externals
            guard let firstData = job.tokens[job.executing].first(where: { nil != $0.data })?.data else {
                break
            }
            // Assign results to promises.
            gateway.gatewayData = job.gatewayData
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
            job.foundCycle = job.foundCycle || cycleDetector.inCycle(data: &job.cycleCache, element: world)
            if true == cycleDetector.inCycle(data: &globalDetectorCache, element: world) {
                if nil == resultID {
                    job.lastState?.edges.insert(KripkeEdge(target: world))
                    continue
                } else if job.foundCycle && handledAllResults {
                    return runs
                }
            }
            // Clone all fsms.
            let clones = job.tokens.enumerated().map { Array(self.cloner.clone(jobs: $1, withLastRecords: job.lastRecords[$0])) }
            // Clone callStack
            let callStack = job.callStack.mapValues { $0.map { CallData(data: $0.data, parameters: $0.parameters, promiseData: $0.promiseData, runs: $0.runs) } }
            // Execute and generate kripke states.
            let generatedRuns = self.executer.execute(
                tokens: clones,
                executing: job.executing,
                withExternals: externals,
                andParameterisedMachines: parameterisedMachines,
                andGateway: gateway,
                andLastState: job.lastState,
                isInitial: job.initial,
                usingView: view,
                andCallStack: callStack,
                andPreviousResults: job.results,
                withDelegate: tokenExecuterDelegate
            )
            // Create new verification states from generatedRuns and add them to runs.
            for run in generatedRuns {
                var newState = job
                newState.lastState = run.lastState
                newState.tokens = run.tokens
                newState.callStack = run.callStack
                newState.gatewayData = run.gatewayData
                newState.results = run.results
                runs.append(newState)
            }
        }
        return runs
    }

}

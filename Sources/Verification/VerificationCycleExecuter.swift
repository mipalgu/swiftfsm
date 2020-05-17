/*
 * VerificationCycleExecuter.swift
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

import FSM
import Gateways
import Hashing
import KripkeStructure
import KripkeStructureViews
import MachineStructure
import ModelChecking
import swiftfsm
import swiftfsm_helpers
import Utilities

final class VerificationCycleExecuter {

    fileprivate let converter: KripkeStatePropertyListConverter
    fileprivate let executer: VerificationTokenExecuter<KripkeStateGenerator>
    fileprivate let worldCreator: WorldCreator = WorldCreator()

    init(
        converter: KripkeStatePropertyListConverter = KripkeStatePropertyListConverter(),
        executer: VerificationTokenExecuter<KripkeStateGenerator> = VerificationTokenExecuter(stateGenerator: KripkeStateGenerator())
    ) {
        self.converter = converter
        self.executer = executer
    }

    fileprivate struct Job<GatewayData> {
        
        let index: Int
        
        let tokens: [[VerificationToken]]
        
        let externals: [(AnySnapshotController, KripkeStatePropertyList)]
        
        let initialState: KripkeState?
        
        let lastState: KripkeState?
        
        let clock: UInt
        
        let clockConstraint: ClockConstraint
        
        let usedClockValues: Set<UInt>
        
        let callStack: [FSM_ID: [CallData]]
        
        let results: [FSM_ID: Any?]
        
        let gatewayData: GatewayData // Fix this type later.
        
    }

    func execute<View: KripkeStructureView, Gateway: VerifiableGateway>(
        tokens: [[VerificationToken]],
        executing: Int,
        withExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andParameterisedMachines parameterisedMachines: [FSM_ID: ParameterisedMachineData],
        andGateway gateway: Gateway,
        andLastState last: KripkeState?,
        isInitial initial: Bool,
        usingView view: View,
        andCallStack callStack: [FSM_ID: [CallData]],
        andPreviousResults results: [FSM_ID: Any?],
        withDelegate delegate: VerificationTokenExecuterDelegate
    ) -> [VerificationRun<Gateway.GatewayData>] where View.State == KripkeState {
        //swiftlint:disable:next line_length
        self.executer.delegate = delegate
        gateway.delegate = self.executer
        var tokens = tokens
        tokens[executing] = tokens[executing].filter { nil != $0.data } // Ignore all skip tokens.
        var jobs = [Job<Gateway.GatewayData>(index: 0, tokens: tokens, externals: externals, initialState: nil, lastState: last, clock: 0, clockConstraint: .equal(value: 0), usedClockValues: [], callStack: callStack, results: results, gatewayData: gateway.gatewayData)]
        let states: Ref<[KripkeStatePropertyList: KripkeState]> = Ref(value: [:])
        var initialStates: HashSink<KripkeStatePropertyList, KripkeStatePropertyList> = HashSink()
        var lastStates: HashSink<KripkeStatePropertyList, KripkeStatePropertyList> = HashSink()
        var runs: [VerificationRun<Gateway.GatewayData>] = []
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            let lastStateName = tokens[executing][job.index].data?.fsm.currentState.name
            let newTokens = self.prepareTokens(job.tokens, executing: (executing, job.index), fromExternals: job.externals, usingCallStack: job.callStack)
            guard let data = newTokens[executing][job.index].data else {
                fatalError("Unable to fetch data of verification token.")
            }
            gateway.gatewayData = job.gatewayData
            let (generatedStates, clockValues, newExternals, newCallStack, newResults) = self.executer.execute(
                fsm: data.fsm.asScheduleableFiniteStateMachine,
                inTokens: newTokens,
                executing: executing,
                atOffset: job.index,
                withExternals: job.externals,
                andClock: job.clock,
                clockConstraint: job.clockConstraint,
                andParameterisedMachines: parameterisedMachines,
                andLastState: job.lastState,
                usingCallStack: job.callStack,
                andPreviousResults: job.results
            )
            guard let first = generatedStates.first else {
                continue
            }
            self.add(generatedStates, to: states)
            if true == initial, nil == job.initialState {
                initialStates.insert(first.properties)
            }
            let lastState = generatedStates.last.map { states.value[$0.properties] ?? $0 }
            // When the clock has been used - try the same token again with new clock values.
            jobs.append(contentsOf: jobsFromClockValues(lastJob: job, clockValues: clockValues))
            if data.fsm.hasFinished {
                gateway.finish(data.id)
            }
            // Add tokens to runs when we have finished executing all of the tokens in a run.
            if job.index + 1 >= tokens[executing].count {
                _ = lastState.map { lastStates.insert($0.properties) }
                var copy = newTokens
                if let data = copy[executing][job.index].data {
                    let newData = VerificationToken.Data(id: data.id, fsm: data.fsm, machine: data.machine, externalVariables: data.externalVariables, parameterisedMachines: data.parameterisedMachines, timeData: data.timeData, clockName: data.clockName, lastFSMStateName: lastStateName)
                    copy[executing][job.index] = .verify(data: newData)
                }
                runs.append(VerificationRun(
                    lastState: lastState,
                    tokens: copy,
                    callStack: newCallStack,
                    gatewayData: gateway.gatewayData,
                    results: newResults
                ))
                continue
            }
            // Add a Job for the next token to execute.
            jobs.append(Job(index: job.index + 1, tokens: newTokens, externals: newExternals, initialState: job.initialState ?? generatedStates.first, lastState: lastState, clock: 0, clockConstraint: .equal(value: 0), usedClockValues: [], callStack: newCallStack, results: newResults, gatewayData: gateway.gatewayData))
        }
        states.value.forEach { (arg: (key: KripkeStatePropertyList, value: KripkeState)) in
            if lastStates.contains(arg.key) {
                return
            }
            view.commit(state: arg.value, isInitial: initial && initialStates.contains(arg.value.properties))
        }
        return runs
    }

    fileprivate func jobsFromClockValues<GatewayData>(lastJob: Job<GatewayData>, clockValues: [UInt]) -> [Job<GatewayData>] {
        let sorted = clockValues.sorted()
        let zipped = zip([0] + sorted, sorted)
        guard let last = sorted.last else {
            return []
        }
        let newClockValues = lastJob.usedClockValues.union(Set(clockValues + [last + 1]))
        let results = zipped.compactMap { (lastValue: UInt, currentValue: UInt) -> Job<GatewayData>? in
            if true == lastJob.usedClockValues.contains(currentValue) || lastValue == currentValue {
                return nil
            }
            return Job(
                index: lastJob.index,
                tokens: lastJob.tokens,
                externals: lastJob.externals,
                initialState: lastJob.initialState,
                lastState: lastJob.lastState,
                clock: currentValue,
                clockConstraint: .and(lhs: .greaterThan(value: lastValue), rhs: .lessThanEqual(value: currentValue)),
                usedClockValues: newClockValues,
                callStack: lastJob.callStack,
                results: lastJob.results,
                gatewayData: lastJob.gatewayData
            )
        }
        guard !lastJob.usedClockValues.contains(last + 1) else {
            return results
        }
        return results + [Job(
            index: lastJob.index,
            tokens: lastJob.tokens,
            externals: lastJob.externals,
            initialState: lastJob.initialState,
            lastState: lastJob.lastState,
            clock: last + 1,
            clockConstraint: .greaterThan(value: last),
            usedClockValues: newClockValues,
            callStack: lastJob.callStack,
            results: lastJob.results,
            gatewayData: lastJob.gatewayData
        )]
    }

    fileprivate func add(_ newStates: [KripkeState], to states: Ref<[KripkeStatePropertyList: KripkeState]>) {
        newStates.forEach {
            // If this is the first time seeing this state then just add it.
            guard let existingState = states.value[$0.properties] else {
                states.value[$0.properties] = $0
                return
            }
            // Attempt to add any new transitions/effects to the kripke state.
            $0.edges.forEach { edge in
                guard let index = existingState.edges.firstIndex(where: { $0.target == edge.target && $0.time == edge.time }) else {
                    existingState.edges.insert(edge)
                    return
                }
                guard let edgeConstraint = edge.constraint else {
                    return
                }
                if let constraint = existingState.edges[index].constraint {
                    existingState.edges.remove(at: index)
                    existingState.edges.insert(KripkeEdge(constraint: .or(lhs: constraint, rhs: edgeConstraint), time: edge.time, target: edge.target))
                    return
                }
                existingState.edges.remove(at: index)
                existingState.edges.insert(edge)
            }
        }
    }

    fileprivate func prepareTokens(
        _ tokens: [[VerificationToken]],
        executing: (Int, Int),
        fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        usingCallStack callStack: [FSM_ID: [CallData]]
    ) -> [[VerificationToken]] {
        guard let data = tokens[executing.0][executing.1].data else {
            fatalError("Unable to fetch data from executing token.")
        }
        let fsm: FSMType
        if let callData = callStack[data.id]?.last {
            fsm = .parameterisedFSM(callData.fsm)
        } else {
            fsm = data.fsm
        }
        let clone = fsm.clone()
        var newTokens = tokens
        newTokens[executing.0][executing.1] = .verify(data: VerificationToken.Data(id: data.id, fsm: clone, machine: data.machine, externalVariables: data.externalVariables, parameterisedMachines: data.parameterisedMachines, timeData: data.timeData, clockName: data.clockName, lastFSMStateName: data.lastFSMStateName))
        newTokens[executing.0].forEach {
            guard var fsm = $0.data?.fsm else {
                return
            }
            fsm.externalVariables.enumerated().forEach { (offset, externalVariables) in
                guard let (external, props) = externals.first(where: { $0.0.name == externalVariables.name }) else {
                    return
                }
                fsm.externalVariables[offset].val = fsm.externalVariables[offset].create(fromDictionary: self.converter.convert(fromList: props))
            }
        }
        return newTokens
    }

}

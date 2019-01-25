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
import Hashing
import KripkeStructure
import KripkeStructureViews
import MachineStructure
import ModelChecking
import swiftfsm
import swiftfsm_helpers
import Utilities

public final class VerificationCycleExecuter {
    
    fileprivate let converter: KripkeStatePropertyListConverter
    fileprivate let executer: VerificationTokenExecuter<KripkeStateGenerator>
    fileprivate let worldCreator: WorldCreator = WorldCreator()
    
    public init(
        converter: KripkeStatePropertyListConverter = KripkeStatePropertyListConverter(),
        executer: VerificationTokenExecuter<KripkeStateGenerator> = VerificationTokenExecuter(stateGenerator: KripkeStateGenerator())
    ) {
        self.converter = converter
        self.executer = executer
    }
    
    fileprivate struct Job {
        
        let index: Int
        
        let tokens: [[VerificationToken]]
        
        let externals: [(AnySnapshotController, KripkeStatePropertyList)]
        
        let initialState: KripkeState?
        
        let lastState: KripkeState?
        
        let clock: UInt
        
        let usedClockValues: [UInt]
        
    }
    
    public func execute<View: KripkeStructureView>(
        tokens: [[VerificationToken]],
        executing: Int,
        withExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andLastState last: KripkeState?,
        isInitial initial: Bool,
        usingView view: View
    ) -> [(KripkeState?, [[VerificationToken]])] where View.State == KripkeState {
        //swiftlint:disable:next line_length
        var tokens = tokens
        tokens[executing] = tokens[executing].filter { nil != $0.data } // Ignore all skip tokens.
        var jobs = [Job(index: 0, tokens: tokens, externals: externals, initialState: nil, lastState: last, clock: 0, usedClockValues: [])]
        let states: Ref<[KripkeStatePropertyList: KripkeState]> = Ref(value: [:])
        var initialStates: HashSink<KripkeStatePropertyList, KripkeStatePropertyList> = HashSink()
        var lastStates: HashSink<KripkeStatePropertyList, KripkeStatePropertyList> = HashSink()
        var runs: [(KripkeState?, [[VerificationToken]])] = []
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            let newTokens = self.prepareTokens(job.tokens, executing: (executing, job.index), fromExternals: job.externals)
            let (generatedStates, clockValues, newExternals) = self.executer.execute(
                fsm: newTokens[executing][job.index].data!.fsm,
                inTokens: newTokens,
                executing: executing,
                atOffset: job.index,
                withExternals: job.externals,
                andClock: job.clock,
                andLastState: job.lastState
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
            // Add tokens to runs when we have finished executing all of the tokens in a run.
            if job.index + 1 >= tokens[executing].count {
                _ = lastState.map { lastStates.insert($0.properties) }
                runs.append((lastState, newTokens))
                continue
            }
            // Add a Job for the next token to execute.
            jobs.append(Job(index: job.index + 1, tokens: newTokens, externals: newExternals, initialState: job.initialState ?? generatedStates.first, lastState: lastState, clock: 0, usedClockValues: []))
        }
        states.value.forEach { (arg: (key: KripkeStatePropertyList, value: KripkeState)) in
            if lastStates.contains(arg.key) {
                return
            }
            view.commit(state: arg.value, isInitial: initial && initialStates.contains(arg.value.properties))
        }
        return runs
    }
    
    fileprivate func jobsFromClockValues(lastJob: Job, clockValues: [UInt]) -> [Job] {
        return clockValues.flatMap { (value: UInt) -> [Job] in
            if true == lastJob.usedClockValues.contains(value) {
                return []
            }
            var arr: [UInt] = []
            arr.reserveCapacity(2)
            if value != UInt.max {
                arr.append(value + 1)
            }
            if value != UInt.min {
                arr.append(value - 1)
            }
            return arr.map {
                Job(
                    index: lastJob.index,
                    tokens: lastJob.tokens,
                    externals: lastJob.externals,
                    initialState: lastJob.initialState,
                    lastState: lastJob.lastState,
                    clock: $0,
                    usedClockValues: lastJob.usedClockValues + clockValues
                )
            }
        }
    }
    
    fileprivate func add(_ newStates: [KripkeState], to states: Ref<[KripkeStatePropertyList: KripkeState]>) {
        newStates.forEach {
            // If this is the first time seeing this state then just add it.
            guard let existingState = states.value[$0.properties] else {
                states.value[$0.properties] = $0
                return
            }
            // Attempt to add any new transitions/effects to the kripke state.
            existingState.effects.formUnion($0.effects)
        }
    }
    
    fileprivate func prepareTokens(_ tokens: [[VerificationToken]], executing: (Int, Int), fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)]) -> [[VerificationToken]] {
        let clone = tokens[executing.0][executing.1].data!.fsm.clone()
        var newTokens = tokens
        newTokens[executing.0][executing.1] = .verify(data: VerificationToken.Data(fsm: clone, machine: tokens[executing.0][executing.1].data!.machine, externalVariables: tokens[executing.0][executing.1].data!.externalVariables, dependencies: tokens[executing.0][executing.1].data!.dependencies))
        newTokens[executing.0].forEach {
            var fsm = $0.data!.fsm
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

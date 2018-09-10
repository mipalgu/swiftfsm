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

import KripkeStructure
import FSM
import Scheduling
import MachineStructure
import ModelChecking
import FSMVerification
import swiftfsm
import Utilities

public final class VerificationCycleKripkeStructureGenerator<
    Cloner: AggregateClonerProtocol,
    Detector: CycleDetector,
    SpinnerConstructor: MultipleExternalsSpinnerConstructorType
>: KripkeStructureGenerator
{
    
    fileprivate let tokens: [[VerificationToken]]
    fileprivate let cloner: Cloner
    fileprivate let cycleDetector: Detector
    fileprivate let executer: VerificationCycleExecuter
    fileprivate let spinnerConstructor: SpinnerConstructor
    fileprivate let worldCreator: WorldCreator
    
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
    }
    
    public func generate() -> KripkeStructure {
        var initialStates: [KripkeState] = []
        var states: Ref<[KripkeStatePropertyList: KripkeState]> = Ref(value: [:])
        var jobs = self.createInitialJobs(fromTokens: self.tokens)
        var i = 0
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            let externalsData = self.fetchUniqueExternalsData(fromSnapshot: job.tokens[job.executing])
            let spinner = self.spinnerConstructor.makeSpinner(forExternals: externalsData)
            while let externals = spinner() {
                if i == 0 {
                    print("\n\n\(jobs.count)\n")
                }
                i = (i + 1) % 10
                // Clone all fsms.
                let clones = job.tokens.enumerated().map {
                    Array(self.cloner.clone(jobs: $1, withLastRecords: job.lastRecords[$0]))
                }
                let world = self.worldCreator.createWorld(
                    fromExternals: externals,
                    andTokens: clones,
                    andLastState: job.lastState,
                    andExecuting: job.executing,
                    andExecutingToken: 0,
                    withState: clones[job.executing][0].fsm.currentState.name,
                    worldType: .beforeExecution
                )
                if nil != states.value[world] {
                    job.lastState?.effects.insert(world)
                    continue
                }
                // Execute and generate kripke states.
                let newStates: [KripkeState] = self.executer.execute(
                    tokens: clones,
                    executing: job.executing,
                    withExternals: externals,
                    andLastState: job.lastState
                )
                // Do not generate more jobs if newStates is empty.
                guard let lastNewState = newStates.last else {
                    continue
                }
                // Add first new state to initial states if necessary.
                if nil == job.lastState {
                    newStates.first.map { initialStates.append($0) }
                }
                // Append the states to the states array.
                // Do not process duplicate states again if nothing has changed.
                if false == self.add(newStates, to: states) {
                    continue
                }
                // Create a new job from the clones.
                jobs.append(Job(
                    cache: job.cache,
                    tokens: clones,
                    executing: (job.executing + 1) % clones.count,
                    lastState: states.value[lastNewState.properties] ?? lastNewState,
                    lastRecords: clones.map { $0.map { $0.fsm.currentRecord } }
                ))
            }
        }
        print("number of initial states: \(initialStates.count)")
        print("number of states: \(states.value.count)")
        return KripkeStructure(initialStates: initialStates, states: states.value)
    }
    
    fileprivate func createInitialJobs(fromTokens tokens: [[VerificationToken]]) -> [Job] {
        return [Job(
            cache: self.cycleDetector.initialData,
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { $0.fsm.currentRecord } }
        )]
    }
    
    fileprivate func fetchUniqueExternalsData(fromSnapshot tokens: [VerificationToken]) -> [ExternalVariablesVerificationData] {
        var hashTable: Set<String> = []
        var externals: [ExternalVariablesVerificationData] = []
        tokens.forEach { $0.externalVariables.forEach {
            if hashTable.contains($0.externalVariables.name) {
                return
            }
            externals.append($0)
        } }
        return externals
    }
    
    fileprivate func add(_ newStates: [KripkeState], to states: Ref<[KripkeStatePropertyList: KripkeState]>) -> Bool {
        var added: Bool = false
        newStates.forEach {
            let state = $0
            // If this is the first time seeing this state then just add it.
            guard let existingState = states.value[state.properties] else {
                states.value[state.properties] = state
                added = true
                return
            }
            // Attempt to add any new transitions/effects to the kripke state.
            let oldCount = existingState.effects.count
            existingState.effects.formUnion(state.effects)
            if false == added {
                added = oldCount < existingState.effects.count
            }
        }
        return added
    }
    
    fileprivate struct Job {
        
        let cache: Detector.Data
        
        let tokens: [[VerificationToken]]
        
        let executing: Int
        
        let lastState: KripkeState?
        
        let lastRecords: [[KripkeStatePropertyList]]
        
    }
    
}

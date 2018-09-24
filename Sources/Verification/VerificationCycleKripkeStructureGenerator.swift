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
>: KripkeStructureGenerator where Detector.Element == KripkeStatePropertyList
{
    
    fileprivate let tokens: [[VerificationToken]]
    fileprivate let cloner: Cloner
    fileprivate let cycleDetector: Detector
    fileprivate let executer: VerificationCycleExecuter
    fileprivate let spinnerConstructor: SpinnerConstructor
    fileprivate let worldCreator: WorldCreator
    
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    
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
        var initialStates: Ref<[KripkeStatePropertyList: KripkeState]> = Ref(value: [:])
        var states: Ref<[KripkeStatePropertyList: KripkeState]> = Ref(value: [:])
        var jobs = self.createInitialJobs(fromTokens: self.tokens)
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            let externalsData = self.fetchUniqueExternalsData(fromSnapshot: job.tokens[job.executing])
            let spinner = self.spinnerConstructor.makeSpinner(forExternals: externalsData)
            while let externals = spinner() {
                // Clone all fsms.
                let clones = job.tokens.enumerated().map {
                    Array(self.cloner.clone(jobs: $1, withLastRecords: job.lastRecords[$0]))
                }
                // Check for cycles.
                let world = self.worldCreator.createWorld(
                    fromExternals: externals,
                    andTokens: clones,
                    andLastState: job.lastState,
                    andExecuting: job.executing,
                    andExecutingToken: 0,
                    withState: clones[job.executing][0].fsm.currentState.name,
                    worldType: .beforeExecution
                )
                let (inCycle, newCache) = self.cycleDetector.inCycle(data: job.cache, element: world)
                if true == inCycle {
                    job.lastState?.effects.insert(world)
                    continue
                }
                // Execute and generate kripke states.
                let (newStates, runs) = self.executer.execute(
                    tokens: clones,
                    executing: job.executing,
                    withExternals: externals,
                    andLastState: job.lastState
                )
                // Append the states to the states array.
                // Do not process duplicate states again if nothing has changed.
                if false == self.add(newStates, to: states) {
                    continue
                }
                for (initialState, lastState, newTokens) in runs {
                    // Add first new state to initial states if necessary.
                    if true == job.initial {
                        _ = initialState.map { _ = self.add([$0], to: initialStates) }
                    }
                    // Do not generate more jobs if we do not have a last state.
                    guard let lastNewState = lastState else {
                        continue
                    }
                    // Create a new job from the clones.
                    jobs.append(Job(
                        initial: false,
                        cache: job.cache,
                        tokens: newTokens,
                        executing: (job.executing + 1) % newTokens.count,
                        lastState: states.value[lastNewState.properties] ?? lastNewState,
                        lastRecords: newTokens.map { $0.map { self.recorder.takeRecord(of: $0.fsm.base) } }
                    ))
                }
            }
        }
        print("number of initial states: \(initialStates.value.count)")
        print("number of state: \(states.value.count)")
        return KripkeStructure(initialStates: Array(initialStates.value.lazy.map { $1 }), states: states.value)
    }
    
    fileprivate func createInitialJobs(fromTokens tokens: [[VerificationToken]]) -> [Job] {
        return [Job(
            initial: true,
            cache: self.cycleDetector.initialData,
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { self.recorder.takeRecord(of: $0.fsm.base) } }
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
            hashTable.insert($0.externalVariables.name)
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
        
        let initial: Bool
        
        let cache: Detector.Data
        
        let tokens: [[VerificationToken]]
        
        let executing: Int
        
        let lastState: KripkeState?
        
        let lastRecords: [[KripkeStatePropertyList]]
        
    }
    
}

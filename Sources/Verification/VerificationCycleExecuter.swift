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
import KripkeStructure
import MachineStructure
import ModelChecking
import swiftfsm
import swiftfsm_helpers

public final class VerificationCycleExecuter {
    
    fileprivate let converter: KripkeStatePropertyListConverter
    fileprivate let executer: VerificationTokenExecuter<KripkeStateGenerator>
    
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
        
    }
    
    public func execute(
        tokens: [[VerificationToken]],
        executing: Int,
        withExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andLastState last: KripkeState?
    ) -> ([KripkeState], [(KripkeState?, KripkeState?, [[VerificationToken]])]) {
        //swiftlint:disable:next line_length
        var jobs = [Job(index: 0, tokens: tokens, externals: externals, initialState: nil, lastState: last, clock: 0)]
        var states: [KripkeState] = []
        var runs: [(KripkeState?, KripkeState?, [[VerificationToken]])] = []
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            let newTokens = self.prepareTokens(job.tokens, executing: (executing, job.index), fromExternals: job.externals)
            let (generatedStates, clockValues, newExternals) = self.executer.execute(
                fsm: newTokens[executing][job.index].fsm,
                inTokens: newTokens,
                executing: executing,
                atOffset: job.index,
                withExternals: job.externals,
                andClock: job.clock,
                andLastState: job.lastState
            )
            states.append(contentsOf: generatedStates)
            // When the clock has been used - try the same token again with new clock values.
            jobs.append(contentsOf: clockValues.map {
                Job(index: job.index, tokens: job.tokens, externals: job.externals, initialState: job.initialState, lastState: job.lastState, clock: $0 + 1)
            })
            // Add tokens to runs when we have finished executing all of the tokens in a run.
            if job.index + 1 >= tokens[executing].count {
                runs.append((job.initialState ?? generatedStates.first, generatedStates.last, newTokens))
                continue
            }
            // Add a Job for the next token to execute.
            jobs.append(Job(index: job.index + 1, tokens: newTokens, externals: newExternals, initialState: job.initialState ?? generatedStates.first, lastState: generatedStates.last, clock: 0))
        }
        return (states, runs)
    }
    
    fileprivate func prepareTokens(_ tokens: [[VerificationToken]], executing: (Int, Int), fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)]) -> [[VerificationToken]] {
        let clone = tokens[executing.0][executing.1].fsm.clone()
        var newTokens = tokens
        newTokens[executing.0][executing.1] = VerificationToken(fsm: clone, machine: tokens[executing.0][executing.1].machine, externalVariables: tokens[executing.0][executing.1].externalVariables)
        newTokens[executing.0].forEach {
            var fsm = $0.fsm
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

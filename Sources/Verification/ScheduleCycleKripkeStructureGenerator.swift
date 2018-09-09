/*
 * ScheduleCycleKripkeStructureGenerator.swift
 * CFSMWrappers
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

public final class ScheduleCycleKripkeStructureGenerator<
    Detector: CycleDetector,
    SpinnerConstructor: MultipleExternalsSpinnerConstructorType,
    Tokenizer: SchedulerTokenizer
>: KripkeStructureGenerator where
    Detector.Element == KripkeStatePropertyList,
    Tokenizer.Object == Machine,
    Tokenizer.SchedulerToken == SchedulerToken
{
    fileprivate let machines: [Machine]
    fileprivate let cycleDetector: Detector
    fileprivate let spinnerConstructor: SpinnerConstructor
    fileprivate let tokenizer: Tokenizer
    fileprivate let jobConverter: VerificationJobSequenceGenerator
    
    public init(
        machines: [Machine],
        cycleDetector: Detector,
        spinnerConstructor: SpinnerConstructor,
        tokenizer: Tokenizer,
        jobConverter: VerificationJobSequenceGenerator = VerificationJobSequenceGenerator()
    ) {
        self.machines = machines
        self.cycleDetector = cycleDetector
        self.spinnerConstructor = spinnerConstructor
        self.tokenizer = tokenizer
        self.jobConverter = jobConverter
    }
    
    public func generate() -> KripkeStructure {
        let tokens = self.tokenizer.separate(self.machines)
        if true == tokens.isEmpty {
            return KripkeStructure(initialStates: [], states: [:])
        }
        var jobs = self.createInitialJobs(fromTokens: tokens)
        var initialStates: [KripkeState] = []
        var states: [KripkeStatePropertyList: KripkeState] = [:]
        // Loop until all jobs are empty.
        while false == jobs.isEmpty {
            let job = jobs.removeFirst()
            // Create spinners
                // Clone into verification jobs.
                // Execute.
                // Assign to states and initial states
                // Add more jobs.
            
        }
        return KripkeStructure(initialStates: initialStates, states: states)
    }
    
    fileprivate func createInitialJobs(fromTokens tokens: [[SchedulerToken]]) -> [Job] {
        return [Job(
            cache: self.cycleDetector.initialData,
            tokens: tokens,
            executing: 0,
            lastState: nil,
            lastRecords: tokens.map { $0.map { $0.fsm.currentRecord } }
        )]
    }
    
    fileprivate struct Job {
        
        let cache: Detector.Data
        
        let tokens: [[VerificationToken]]
        
        let executing: Int
        
        let lastState: KripkeState?
        
        let lastRecords: [[KripkeStatePropertyList]]
        
    }
    
    fileprivate struct VerificationToken {
        
        let fsm: AnyScheduleableFiniteStateMachine
        
        let machine: Machine
        
        let externalVariables: [ExternalVariablesData]
        
    }
    
    fileprivate struct ExternalVariablesData {
        
        let externalVariables: AnySnapshotController
        
        let defaultValues: KripkeStatePropertyList
        
        let spinners: [String: (Any) -> Any?]
        
    }
    
}

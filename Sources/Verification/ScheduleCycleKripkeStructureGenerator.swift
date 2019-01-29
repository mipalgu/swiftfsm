/*
 * ScheduleCycleKripkeStructureGenerator.swift
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
import KripkeStructureViews
import FSM
import Gateways
import Scheduling
import MachineStructure
import ModelChecking
import FSMVerification
import swiftfsm

public final class ScheduleCycleKripkeStructureGenerator<
    Extractor: ExternalsSpinnerDataExtractorType,
    Factory: VerificationCycleKripkeStructureGeneratorFactoryType,
    Tokenizer: SchedulerTokenizer,
    ViewFactory: KripkeStructureViewFactory
>: KripkeStructureGenerator where
    Tokenizer.Object == Machine,
    Tokenizer.SchedulerToken == SchedulerToken,
    ViewFactory.View.State == KripkeState
{
    fileprivate let machines: [Machine]
    fileprivate let extractor: Extractor
    fileprivate let factory: Factory
    fileprivate let tokenizer: Tokenizer
    fileprivate let viewFactory: ViewFactory
    
    public init(
        machines: [Machine],
        extractor: Extractor,
        factory: Factory,
        tokenizer: Tokenizer,
        viewFactory: ViewFactory
    ) {
        self.machines = machines
        self.extractor = extractor
        self.factory = factory
        self.tokenizer = tokenizer
        self.viewFactory = viewFactory
    }
    
    public func generate<Gateway: ModifiableFSMGateway>(usingGateway gateway: Gateway) {
        let tokens = self.tokenizer.separate(self.machines)
        tokens.forEach {
            $0.forEach {
                switch $0.type {
                case .parameterisedFSM(let fsm):
                    fsm.suspend()
                default:
                    return
                }
            }
        }
        let verificationTokens = self.convert(tokens: tokens, forMachines: self.machines)
        verificationTokens.forEach { (tokens: [[VerificationToken]], view: ViewFactory.View) in
            var generator = self.factory.make(tokens: tokens)
            generator.delegate = self
            generator.generate(usingGateway: gateway, andView: view)
        }
    }
    
    /*
     *  Creates an list of schedules where each list only contains fsms for a
     *  particular machine.
     *
     *  This allows us to create a Kripke Structure for each machine. This is
     *  possible because an FSM may only manipulate or control other FSM's
     *  within the same machine.
     */
    fileprivate func convert(tokens: [[SchedulerToken]], forMachines machines: [Machine]) -> [([[VerificationToken]], ViewFactory.View)] {
        return machines.map { machine in
            let verificationTokens = tokens.map { (arr: [SchedulerToken]) in
                arr.map { (token: SchedulerToken) -> VerificationToken in
                    if true == self.shouldSkip(token: token, forMachine: machine) {
                        return .skip
                    }
                    let externals = token.fsm.externalVariables.map { (external: AnySnapshotController) -> ExternalVariablesVerificationData in
                        let (defaultValues, spinners) = self.extractor.extract(externalVariables: external)
                        return ExternalVariablesVerificationData(externalVariables: external, defaultValues: defaultValues, spinners: spinners)
                    }
                    return .verify(data: VerificationToken.Data(fsm: token.fsm, machine: token.machine, externalVariables: externals))
                }
            }
            let view = self.viewFactory.make(identifier: machine.name)
            return (verificationTokens, view)
        }
    }
    
    fileprivate func shouldSkip(token: SchedulerToken, forMachine machine: Machine) -> Bool {
        if token.machine != machine {
            return true
        }
        if machine.name + "." + machine.fsm.name == token.fullyQualifiedName {
            return false
        }
        let dependency = self.findDependency(forToken: token, inDependencies: machine.dependencies, machine.name + "." + machine.fsm.name)
        if true == dependency.isEmpty {
            return false
        }
        let isCallableMachine = nil == dependency.first {
            switch $0 {
            case .callableParameterisedMachine:
                return true
            default:
                return false
            }
        }
        if true == isCallableMachine {
            return true
        }
        return false
    }
    
    fileprivate func findDependency(forToken token: SchedulerToken, inDependencies dependencies: [Dependency], _ name: String = "") -> [Dependency] {
        for dep in dependencies {
            let fsmName: String
            switch dep {
            case .callableParameterisedMachine(let fsm, _):
                fsmName = fsm.name
            case .invokableParameterisedMachine(let fsm, _):
                fsmName = fsm.name
            case .submachine(let fsm, _):
                fsmName = fsm.name
            }
            if name + "." + fsmName == token.fullyQualifiedName {
                return [dep]
            }
        }
        for dep in dependencies {
            switch dep {
            case .callableParameterisedMachine(let fsm, let dependencies):
                return [dep] + findDependency(forToken: token, inDependencies: dependencies, name + "." + fsm.name)
            case .invokableParameterisedMachine(let fsm, let dependencies):
                return [dep] + findDependency(forToken: token, inDependencies: dependencies, name + "." + fsm.name)
            case .submachine(let fsm, let dependencies):
                return [dep] + findDependency(forToken: token, inDependencies: dependencies, name + "." + fsm.name)
            }
            
        }
        return []
    }
    
}

extension ScheduleCycleKripkeStructureGenerator: LazyKripkeStructureGeneratorDelegate {
    
    public func statesForParameterisedMachine(_ generator: LazyKripkeStructureGenerator, fsm: AnyParameterisedFiniteStateMachine) -> ([KripkeState], [KripkeState]?) {
        return ([], [])
    }
    
}

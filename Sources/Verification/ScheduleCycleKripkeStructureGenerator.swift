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
import swift_helpers

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
    
    fileprivate var resultsCache: [String: SortedCollection<(UInt, Any?)>] = [:]
    
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
        self.machines.forEach {
            self.add(fsm: $0.fsm, toGateway: gateway, withDependencies: $0.dependencies, name: $0.name)
        }
        let tokens = self.tokenizer.separate(self.machines)
        let verificationTokens = self.convert(tokens: tokens, forMachines: self.machines, usingGateway: gateway)
        verificationTokens.forEach { (tokens: [[VerificationToken]], view: AnyKripkeStructureView<KripkeState>) in
            var generator = self.factory.make(tokens: tokens)
            generator.delegate = self
            generator.generate(usingGateway: gateway, andView: view, storingResultsFor: nil)
        }
    }
    
    fileprivate func add<Gateway: ModifiableFSMGateway>(fsm: FSMType, toGateway gateway: Gateway, withDependencies dependencies: [Dependency], name: String) {
        let name = name + "." + fsm.name
        gateway.fsms[gateway.id(of: name)] = fsm
        gateway.setup(gateway.id(of: name))
        dependencies.forEach {
            switch $0 {
            case .callableParameterisedMachine(let fsm, let dependencies), .invokableParameterisedMachine(let fsm, let dependencies):
                fsm.suspend()
                self.add(fsm: .parameterisedFSM(fsm), toGateway: gateway, withDependencies: dependencies, name: name)
            case .submachine(let fsm, let dependencies):
                self.add(fsm: .controllableFSM(fsm), toGateway: gateway, withDependencies: dependencies, name: name)
            }
        }
    }
    
    /*
     *  Creates an list of schedules where each schedule only contains fsms for
     *  a particular machine.
     *
     *  This allows us to create a Kripke Structure for each machine. This is
     *  possible because an FSM may only manipulate or control other FSM's
     *  within the same machine.
     */
    fileprivate func convert<Gateway: FSMGateway>(tokens: [[SchedulerToken]], forMachines machines: [Machine], usingGateway gateway: Gateway) -> [([[VerificationToken]], AnyKripkeStructureView<KripkeState>)] {
        return machines.map { machine in
            switch machine.fsm {
            case .parameterisedFSM(let fsm):
                return self.schedule(forDependency: .invokableParameterisedMachine(fsm, machine.dependencies), inMachine: machine, usingTokens: tokens, andGateway: gateway)
            case .controllableFSM(let fsm):
                return self.schedule(forDependency: .submachine(fsm, machine.dependencies), inMachine: machine, usingTokens: tokens, andGateway: gateway)
            }
        }
    }
    
    fileprivate func schedule<Gateway: FSMGateway>(forDependency dependency: Dependency, inMachine machine: Machine, usingTokens tokens: [[SchedulerToken]], andGateway gateway: Gateway) -> ([[VerificationToken]], AnyKripkeStructureView<KripkeState>) {
        let verificationTokens = tokens.map { (arr: [SchedulerToken]) in
            arr.map { (token: SchedulerToken) -> VerificationToken in
                // Check to see if we can skip this token.
                if token.machine != machine {
                    return .skip
                }
                let dependencyPath = self.fetchDependencyPath(forToken: token, inDependencies: machine.dependencies)
                if machine.name + "." + machine.fsm.name != token.fullyQualifiedName && true == self.shouldSkip(token: token, inDependencyPath: dependencyPath) {
                    return .skip
                }
                // Create the token data since we cannot skip this token.
                let externals = token.fsm.externalVariables.map { (external: AnySnapshotController) -> ExternalVariablesVerificationData in
                    let (defaultValues, spinners) = self.extractor.extract(externalVariables: external)
                    return ExternalVariablesVerificationData(externalVariables: external, defaultValues: defaultValues, spinners: spinners)
                }
                let callableTokens = self.createCallableTokens(forToken: token, inDependencies: dependency.dependencies, inMachine: machine, withTokens: tokens, usingGateway: gateway)
                let parameterisedMachines = self.fetchParameterisedMachines(forDependency: dependency, withFullyQualifiedName: token.fullyQualifiedName, inGateway: gateway)
                return .verify(data: VerificationToken.Data(id: gateway.id(of: token.fullyQualifiedName), fsm: dependencyPath.last?.fsm ?? token.machine.fsm, machine: token.machine, externalVariables: externals, callableMachines: callableTokens, parameterisedMachines: parameterisedMachines))
            }
        }
        let view = self.viewFactory.make(identifier: machine.name)
        return (verificationTokens, AnyKripkeStructureView(view))
    }
    
    fileprivate func fetchParameterisedMachines<Gateway: FSMGateway>(forDependency dependency: Dependency, withFullyQualifiedName fullyQualifiedName: String, inGateway gateway: Gateway) -> [FSM_ID: (String, AnyParameterisedFiniteStateMachine)] {
        return Dictionary(uniqueKeysWithValues: dependency.dependencies.compactMap { (dependency) -> (FSM_ID, (String, AnyParameterisedFiniteStateMachine))? in
            switch dependency {
            case .callableParameterisedMachine(let fsm, _), .invokableParameterisedMachine(let fsm, _):
                let fullyQualifiedName = fullyQualifiedName + "." + fsm.name
                return (gateway.id(of: fullyQualifiedName), (fullyQualifiedName, fsm))
            default:
                return nil
            }
        })
    }
    
    fileprivate func createCallableTokens<Gateway: FSMGateway>(forToken token: SchedulerToken, inDependencies dependencies: [Dependency], inMachine machine: Machine, withTokens tokens: [[SchedulerToken]], usingGateway gateway: Gateway) -> [FSM_ID: (String, [[VerificationToken]], AnyKripkeStructureView<KripkeState>)] {
        let callableDependencies = dependencies.lazy.filter {
            switch $0 {
            case .callableParameterisedMachine:
                return true
            default:
                return false
            }
        }
        let callableDependenciesTokens = callableDependencies.map { self.schedule(forDependency: $0, inMachine: machine, usingTokens: tokens, andGateway: gateway) }
        return Dictionary(uniqueKeysWithValues: zip(callableDependencies, callableDependenciesTokens).map {
            let fullyQualifiedName = token.fullyQualifiedName + "." + $0.fsm.name
            return (gateway.id(of: fullyQualifiedName), (fullyQualifiedName, $1.0, $1.1))
        })
    }
    
    /**
     *  Should we skip this token if we are generating a `KripkeStructure` for
     *  `machine`?
     *
     *  - Parameter token: The `SchedulerToken` which we are asking whether we
     *  should skip it or not.
     *
     *  - Parameter machine: The `Machine` that the `KripkeStructure` is being
     *  generated for.
     *
     *  - Returns: Returns true if `token` should be skipped.
     */
    fileprivate func shouldSkip(token: SchedulerToken, inDependencyPath dependencyPath: [Dependency]) -> Bool {
        if true == dependencyPath.isEmpty {
            return false
        }
        // Skip if the token represents a machine that has parants that are callable parameterised machines.
        let isCallableMachine = nil == dependencyPath.first {
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
    
    /**
     *  Finds the dependency path leading to the dependency represented by the
     *  token.
     *
     *  - Parameter token: The `SchedulerToken` that we are trying to find in
     *  the dependency tree.
     *
     *  - Parameter dependencies: All dependencies at a particular level of the
     *  dependency tree.
     *
     *  - Returns: An array where the first element is the root node of the
     *  dependency tree where each subsequent element is the dependency of the
     *  element preceeding it. The last element is therefore the dependency
     *  represented by the token.
     */
    fileprivate func fetchDependencyPath(forToken token: SchedulerToken, inDependencies dependencies: [Dependency], _ name: String = "") -> [Dependency] {
        for dep in dependencies {
            if name + "." + dep.fsm.name == token.fullyQualifiedName {
                return [dep]
            }
        }
        for dep in dependencies {
            let subpath = self.fetchDependencyPath(forToken: token, inDependencies: dep.dependencies, name + "." + dep.fsm.name)
            if false == subpath.isEmpty {
                return [dep] + subpath
            }
        }
        return []
    }
    
}

extension ScheduleCycleKripkeStructureGenerator: LazyKripkeStructureGeneratorDelegate {
    
    public func resultsForCall<Gateway: ModifiableFSMGateway>(_ generator: LazyKripkeStructureGenerator, call callData: CallData, withGateway gateway: Gateway) -> SortedCollection<(UInt, Any?)> {
        let key = "id: \(callData.id), parameters: \(callData.parameters)"
        if let results = self.resultsCache[key] {
            return results
        }
        var generator = self.factory.make(tokens: callData.tokens)
        generator.delegate = self
        guard let results = generator.generate(usingGateway: gateway, andView: callData.view, storingResultsFor: callData.id) else {
            swiftfsmError("Call to parameterised machine '\(callData.fullyQualifiedName)' that may never return.")
        }
        self.resultsCache[key] = results
        return results
    }
    
}

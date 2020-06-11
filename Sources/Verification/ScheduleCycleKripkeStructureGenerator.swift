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

public final class ScheduleCycleKripkeStructureGenerator<
    Extractor: ExternalsSpinnerDataExtractorType,
    Factory: ParameterisedVerificationCycleKripkeStructureGeneratorFactoryType,
    Tokenizer: SchedulerTokenizer,
    ViewFactory: KripkeStructureViewFactory
>: KripkeStructureGenerator where
    Tokenizer.Object == Machine,
    Tokenizer.DispatchTable.Token: VerifiableDispatchTableTokenProtocol,
    ViewFactory.View.State == KripkeState
{
    fileprivate let dispatchTable: MetaDispatchTable?
    fileprivate let machines: [Machine]
    fileprivate let extractor: Extractor
    fileprivate let factory: Factory
    fileprivate let tokenizer: Tokenizer
    fileprivate let viewFactory: ViewFactory

    fileprivate var viewCache: [String: AnyKripkeStructureView<KripkeState>] = [:]

    fileprivate var resultsCache: [String: SortedCollection<(UInt, Any?)>] = [:]

    fileprivate let recorder: MirrorKripkePropertiesRecorder = MirrorKripkePropertiesRecorder()

    public init(
        dispatchTable: MetaDispatchTable? = nil,
        machines: [Machine],
        extractor: Extractor,
        factory: Factory,
        tokenizer: Tokenizer,
        viewFactory: ViewFactory
    ) {
        self.dispatchTable = dispatchTable
        self.machines = machines
        self.extractor = extractor
        self.factory = factory
        self.tokenizer = tokenizer
        self.viewFactory = viewFactory
    }

    public func generate<Gateway: VerifiableGateway>(usingGateway gateway: Gateway) {
        self.machines.forEach {
            self.add(fsm: $0.fsm, toGateway: gateway, withDependencies: $0.dependencies, name: $0.name)
        }
        // Split all machines into a collection of `SchedulerToken`s.
        let tokens = self.tokenizer.separate(self.machines)
        let dispatchTable = self.dispatchTable.flatMap { self.tokenizer.fetchDispatchTable(fromTokens: tokens, referencing: $0) }
        // Convert these `SchedulerToken`s to `VerificationToken`s.
        let verificationTokens = self.convert(tokens: tokens, forMachines: self.machines, usingGateway: gateway, dispatchTable: dispatchTable)
        let temp = verificationTokens.flatMap { $0.0.flatMap { $0.compactMap { (token: VerificationToken) -> (FSM_ID, String, [FSM_ID: ParameterisedMachineData])? in
            guard let data = token.data else {
                return nil
            }
            return (data.id, data.fsm.name, data.parameterisedMachines)
        }}}
        // Reset all views so that we may reuse views that have previously been used.
        self.viewCache.forEach {
            $1.reset(usingClocks: self.dispatchTable != nil)
        }
        // Generate a separate kripke structure for each collection of verification token.
        // This allows the creation of isolated kripke structures based on the
        // dependencies between machines.
        let data = gateway.gatewayData
        verificationTokens.forEach { (tokens: [[VerificationToken]], view: AnyKripkeStructureView<KripkeState>) in
            gateway.gatewayData = data
            var generator = self.factory.make(tokens: tokens)
            generator.delegate = self
            generator.generate(usingGateway: gateway, andView: view, storingResultsFor: nil)
        }
        self.viewCache.forEach {
            $1.finish()
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
    fileprivate func convert<Gateway: FSMGateway>(tokens: [[SchedulerToken]], forMachines machines: [Machine], usingGateway gateway: Gateway, dispatchTable: Tokenizer.DispatchTable?) -> [([[VerificationToken]], AnyKripkeStructureView<KripkeState>)] {
        return machines.map { machine in
            let dep = self.convertRootFSMToDependency(inMachine: machine)
            return self.schedule(forDependency: dep, inMachine: machine, usingTokens: tokens, andGateway: gateway, parents: [], dispatchTable: dispatchTable)
        }
    }

    fileprivate func convertRootFSMToDependency(inMachine machine: Machine) -> Dependency {
        switch machine.fsm {
        case .parameterisedFSM(let fsm):
            return .invokableParameterisedMachine(fsm, machine.dependencies)
        case .controllableFSM(let fsm):
            return .submachine(fsm, machine.dependencies)
        }
    }

    fileprivate func schedule<Gateway: FSMGateway>(
        forDependency dependency: Dependency,
        inMachine machine: Machine,
        usingTokens tokens: [[SchedulerToken]],
        andGateway gateway: Gateway,
        parents: [Dependency],
        dispatchTable: Tokenizer.DispatchTable?
    ) -> ([[VerificationToken]], AnyKripkeStructureView<KripkeState>) {
        let dependencyFullyQualifiedName = (parents + [dependency]).reduce(machine.name) { $0 + "." + $1.fsm.name }
        let cycleLength: UInt
        if let dispatchTable = dispatchTable {
            cycleLength = dispatchTable.timeslots.reduce(0) {
                max($0, ($1.last.map { $0.startTime + $0.duration } ?? 0))
            }
        } else {
            cycleLength = 0
        }
        let verificationTokens = tokens.map { (arr: [SchedulerToken]) in
            arr.map { (token: SchedulerToken) -> VerificationToken in
                let dispatchToken = Tokenizer.DispatchTable.Token(
                    id: gateway.id(of: token.fullyQualifiedName),
                    fsm: token.fsm,
                    machine: token.machine,
                    fullyQualifiedName: token.fullyQualifiedName
                )
                let timeData: VerificationToken.TimeData?
                if let timeslot = dispatchTable?.findTimeslot(for: dispatchToken) {
                    timeData = VerificationToken.TimeData(startTime: timeslot.startTime, duration: timeslot.duration, cycleLength: cycleLength)
                } else {
                    timeData = nil
                }
                // Check to see if we can skip this token.
                if token.machine != machine {
                    return .skip(data: timeData)
                }
                if self.token(token, inDependencies: parents) {
                    return .skip(data: timeData)
                }
                let dependencyPath = self.fetchDependencyPath(forToken: token, inDependencies: machine.dependencies, machine.name + "." + machine.fsm.name)
                let isRootOfToken =
                    dependencyPath.isEmpty
                    && machine.name + "." + machine.fsm.name == token.fullyQualifiedName
                if !isRootOfToken && token.fullyQualifiedName != dependencyFullyQualifiedName && self.shouldSkip(token: token, inDependencyPath: dependencyPath)  {
                    return .skip(data: timeData)
                }
                let dependency = dependencyPath.last ?? convertRootFSMToDependency(inMachine: machine)
                // Create the token data since we cannot skip this token.
                let externals = token.fsm.externalVariables.map { (external: AnySnapshotController) -> ExternalVariablesVerificationData in
                    let (defaultValues, spinners) = self.extractor.extract(externalVariables: external)
                    return ExternalVariablesVerificationData(externalVariables: external, defaultValues: defaultValues, spinners: spinners)
                }
                let parameterisedMachines = self.fetchParameterisedMachines(
                    forDependency: dependency,
                    inMachine: machine,
                    withFullyQualifiedName: token.fullyQualifiedName,
                    withTokens: tokens,
                    inGateway: gateway,
                    parents: isRootOfToken ? [self.convertRootFSMToDependency(inMachine: token.machine)] : Array(dependencyPath.dropLast()),
                    dispatchTable: dispatchTable
                )
                return .verify(data: VerificationToken.Data(id: gateway.id(of: token.fullyQualifiedName), fsm: dependencyPath.last?.fsm ?? token.machine.fsm, machine: token.machine, externalVariables: externals, parameterisedMachines: parameterisedMachines, timeData: timeData, clockName: token.fullyQualifiedName + ".clock", lastFSMStateName: nil))
            }
        }
        let identifier = parents.isEmpty ? machine.name : dependencyFullyQualifiedName
        guard let view = self.viewCache[identifier] else {
            let view = AnyKripkeStructureView(self.viewFactory.make(identifier: identifier))
            self.viewCache[identifier] = view
            return (verificationTokens, view)
        }
        return (verificationTokens, view)
    }

    fileprivate func token(_ token: SchedulerToken, inDependencies dependencies: [Dependency]) -> Bool {
        func search(_ dependencies: [Dependency], pre: String) -> Bool {
            return nil != dependencies.first {
                let name = pre + "." + $0.fsm.name
                return name == token.fullyQualifiedName
            }
        }
        return search(dependencies, pre: token.machine.name)
    }

    fileprivate func fetchParameterisedMachines<Gateway: FSMGateway>(
        forDependency dependency: Dependency,
        inMachine machine: Machine,
        withFullyQualifiedName fullyQualifiedName: String,
        withTokens tokens: [[SchedulerToken]],
        inGateway gateway: Gateway,
        parents: [Dependency],
        dispatchTable: Tokenizer.DispatchTable?
    ) -> [FSM_ID: ParameterisedMachineData] {
        return Dictionary(uniqueKeysWithValues: dependency.dependencies.compactMap { (dependency) -> (FSM_ID, ParameterisedMachineData)? in
            let inPlace: Bool
            let id: FSM_ID
            let fsm: AnyParameterisedFiniteStateMachine
            switch dependency {
            case .invokableParameterisedMachine(let localFsm, _):
                id = gateway.id(of: fullyQualifiedName + "." + localFsm.name)
                inPlace = true
                fsm = localFsm
            case .callableParameterisedMachine(let localFsm, _):
                inPlace = false
                id = gateway.id(of: fullyQualifiedName)
                fsm = localFsm
            default:
                return nil
            }
            let fullyQualifiedName = fullyQualifiedName + "." + fsm.name
            let (tokens, view) = self.schedule(forDependency: dependency, inMachine: machine, usingTokens: tokens, andGateway: gateway, parents: parents, dispatchTable: dispatchTable)
            view.reset(usingClocks: dispatchTable != nil)
            return (
                id,
                ParameterisedMachineData(
                    id: id,
                    fsm: fsm,
                    fullyQualifiedName: fullyQualifiedName,
                    parameters: Set(self.recorder.takeRecord(of: fsm.parameters).propertiesDictionary.keys),
                    inPlace: inPlace,
                    tokens: tokens,
                    view: view
                )
            )
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
        // Skip if the token represents a machine that has parants that are callable parameterised machines.
        let isCallableMachine = nil != dependencyPath.first {
            switch $0 {
            case .callableParameterisedMachine, .invokableParameterisedMachine:
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

    public func resultsForCall<Gateway: VerifiableGateway>(_ generator: LazyKripkeStructureGenerator, call callData: CallData, withGateway gateway: Gateway) -> SortedCollection<(UInt, Any?)> {
        if nil == callData.tokens.first(where: { nil != $0.first(where: { nil != $0.data }) }) {
            return SortedCollection<(UInt, Any?)>() { (_, _) -> ComparisonResult in
                return .orderedAscending
            }
        }
        let key = "id: \(callData.id), parameters: \(callData.parameters.sorted { $0.key < $1.key })"
        if let results = self.resultsCache[key] {
            return results
        }
        var generator = self.factory.make(tokens: callData.tokens)
        generator.delegate = self
        guard true == callData.fsm.parametersFromDictionary(callData.parameters) else {
            swiftfsmError("Unable to call machine.")
        }
        callData.fsm.restart()
        guard let results = generator.generate(usingGateway: gateway, andView: callData.view, storingResultsFor: callData.id) else {
            swiftfsmError("Call to parameterised machine '\(callData.fullyQualifiedName)' that may never return.")
        }
        self.resultsCache[key] = results
        return results
    }

}

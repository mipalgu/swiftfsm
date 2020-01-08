/*
 * MachinesMachineLoader.swift 
 * MachineLoading 
 *
 * Created by Callum McColl on 02/07/2018.
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

#if !NO_FOUNDATION && canImport(Foundation)

import SwiftMachines

#endif

import FSM
import Libraries
import swiftfsm
import IO
import Gateways
import swift_helpers

@available(macOS 10.11, *)
public final class MachinesMachineLoader: MachineLoader {

    fileprivate typealias SymbolSignature = @convention(c) (Any, Any, Any) -> Any

    #if !NO_FOUNDATION && canImport(Foundation)
    fileprivate let compiler: MachineCompiler<MachineAssembler>
    fileprivate let parser: MachineParser
    #endif
    
    fileprivate let libraryLoader: ShallowLibraryMachineLoader
    fileprivate let printer: Printer
    
    fileprivate let buildDir: String
    fileprivate let cCompilerFlags: [String]
    fileprivate let cxxCompilerFlags: [String]
    fileprivate let linkerFlags: [String]
    fileprivate let swiftCompilerFlags: [String]
    fileprivate let swiftBuildFlags: [String]
    
    #if !NO_FOUNDATION && canImport(Foundation)
    @available(macOS 10.11, *)
    public init(
        compiler: MachineCompiler<MachineAssembler> = MachineCompiler(assembler: MachineAssembler()),
        loader: LibrarySymbolLoader,
        parser: MachineParser = MachineParser(),
        printer: Printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream()),
        buildDir: String = ".build",
        cCompilerFlags: [String] = [],
        cxxCompilerFlags: [String] = [],
        linkerFlags: [String] = [],
        swiftCompilerFlags: [String] = [],
        swiftBuildFlags: [String] = []
    ) {
        self.compiler = compiler
        self.libraryLoader = ShallowLibraryMachineLoader(loader: loader, printer: printer)
        self.parser = parser
        self.printer = printer
        self.buildDir = buildDir
        self.cCompilerFlags = cCompilerFlags
        self.cxxCompilerFlags = cxxCompilerFlags
        self.linkerFlags = linkerFlags
        self.swiftCompilerFlags = swiftCompilerFlags
        self.swiftBuildFlags = swiftBuildFlags
    }
    #else
    
    public init(
        loader: LibrarySymbolLoader,
        printer: Printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream()),
        buildDir: String = ".build",
        cCompilerFlags: [String] = [],
        cxxCompilerFlags: [String] = [],
        linkerFlags: [String] = [],
        swiftCompilerFlags: [String] = [],
        swiftBuildFlags: [String] = []
    ) {
        self.libraryLoader = ShallowLibraryMachineLoader(loader: loader, printer: printer)
        self.printer = printer
        self.buildDir = buildDir
        self.cCompilerFlags = cCompilerFlags
        self.cxxCompilerFlags = cxxCompilerFlags
        self.linkerFlags = linkerFlags
        self.swiftCompilerFlags = swiftCompilerFlags
        self.swiftBuildFlags = swiftBuildFlags
    }
    
    #endif
    
    public func load<Gateway: FSMGateway>(name: String, gateway: Gateway, clock: Timer, path: String) -> (FSMType, [Dependency])? {
        // Attempt to load the machine from the compiled libs.
        let buildDir = path + "/" + self.buildDir
        if let data = self.loadCompiledMachine(name: name, gateway: gateway, clock: clock, path: buildDir, prefix: name) {
            return data
        }
        #if !NO_FOUNDATION && canImport(Foundation)
        // If we can't load the machine because it is not compiled, then compile and try to load it again.
        if let machine = self.parser.parseMachine(atPath: path) {
            return load(machine: machine, gateway: gateway, clock: clock, prefix: name)
        }
        self.parser.errors.forEach(self.printer.error)
        #endif
        return nil
    }
    
#if !NO_FOUNDATION && canImport(Foundation)

    fileprivate func load<Gateway: FSMGateway>(machine: Machine, gateway: Gateway, clock: Timer, prefix: String, caller: FSM_ID? = nil) -> (FSMType, [Dependency])? {
        let dependantMachines = machine.submachines + machine.parameterisedMachines
        let selfID: FSM_ID = gateway.id(of: prefix + "." + machine.name)
        let caller = caller ?? selfID
        let newGateway = self.createRestrictiveGateway(
            forMachine: machine.name,
            gateway: gateway,
            dependantMachines: dependantMachines.map { $0.name },
            callableMachines: machine.callableMachines.map { $0.name },
            invocableMachines: machine.invocableMachines.map { $0.name },
            prefix: prefix,
            selfID: selfID,
            caller: caller
        )
        guard let recursed = dependantMachines.failMap({ (m: Machine) -> Dependency? in
            let id = newGateway.id(of: m.name)
            let caller = true == machine.callableMachines.lazy.map { $0.name }.contains(m.name) ? caller : id
            return load(
                machine: m,
                gateway: gateway,
                clock: clock,
                prefix: prefix + "." + machine.name,
                caller: caller
            ).map { convert($0, dependencies: $1, inMachine: machine) }
        }) else {
            return nil
        }
        if false == self.compiler.shouldCompile(machine, inDirectory: self.buildDir) {
            let outputPath = self.compiler.outputPath(forMachine: machine, builtInDirectory: self.buildDir)
            guard let fsm = self.loadSymbol(inMachine: machine.name, gateway: newGateway, clock: clock, path: outputPath, caller: caller) else {
                return nil
            }
            return (fsm, recursed)
        }
        guard
            let outputPath = self.compiler.compile(
                machine,
                withBuildDir: self.buildDir,
                withCCompilerFlags: self.cCompilerFlags,
                andCXXCompilerFlags: self.cxxCompilerFlags,
                andLinkerFlags: self.linkerFlags,
                andSwiftCompilerFlags: self.swiftCompilerFlags,
                andSwiftBuildFlags: self.swiftBuildFlags
            )
        else {
            self.compiler.errors.forEach(self.printer.error)
            return nil
        }
        guard let fsm = self.loadSymbol(inMachine: machine.name, gateway: newGateway, clock: clock, path: outputPath, caller: caller) else {
            return nil
        }
        return (fsm, recursed)
    }

    fileprivate func loadSymbol<G: FSMGateway>(inMachine name: String, gateway: G, clock: Timer, path: String, caller: FSM_ID) -> FSMType? {
        return self.libraryLoader.load(name: name, gateway: gateway, clock: clock, path: path)?.0
    }

    fileprivate func convert(_ fsm: FSMType, dependencies: [Dependency], inMachine machine: Machine) -> Dependency {
        switch fsm {
        case .controllableFSM(let fsm):
            return .submachine(fsm, dependencies)
        case .parameterisedFSM(let fsm):
            if machine.callableMachines.contains(where: { $0.name == fsm.name }) {
                return .callableParameterisedMachine(fsm, dependencies)
            }
            return .invokableParameterisedMachine(fsm, dependencies)
        }
    }
    
#endif
    
    fileprivate func loadCompiledMachine<Gateway: FSMGateway>(name: String, gateway: Gateway, clock: Timer, path: String, prefix: String, caller: FSM_ID? = nil) -> (FSMType, [Dependency])? {
        #if os(macOS)
        let ext = "dylib"
        #else
        let ext = "so"
        #endif
        let libPath = path + "/" + name + "." + ext
        guard let (fsm, dependencies) = self.libraryLoader.load(name: name, gateway: gateway, clock: clock, path: libPath) else {
            return nil
        }
        let dependantMachines = dependencies.map { $0.name }
        let callableMachines = dependencies.filter { $0.isCallable }.map { $0.name }
        let invocableMachines = dependencies.filter { $0.isInvokable }.map {$0.name }
        let selfID: FSM_ID = gateway.id(of: prefix + "." + name)
        let caller = caller ?? selfID
        let newGateway = self.createRestrictiveGateway(forMachine: name, gateway: gateway, dependantMachines: dependantMachines, callableMachines: callableMachines, invocableMachines: invocableMachines, prefix: prefix, selfID: selfID, caller: caller)
        guard let allDependencies = dependencies.failMap({ (m: ShallowDependency) -> Dependency? in
            let id = newGateway.id(of: m.name)
            // Set the caller to the parent caller when we are calling machines.
            let caller = true == callableMachines.contains(m.name) ? caller : id
            let newDirectory = path + "/" + m.name + "Dependencies"
            guard let (fsm, dependencies) = self.loadCompiledMachine(name: m.name, gateway: gateway, clock: clock, path: newDirectory, prefix: prefix + "." + m.name, caller: caller) else {
                return nil
            }
            switch m {
            case .callableMachine:
                guard let parameterisedMachine = fsm.asParameterisedFiniteStateMachine else {
                    return nil
                }
                return Dependency.callableParameterisedMachine(parameterisedMachine, dependencies)
            case .invokableMachine:
                guard let parameterisedMachine = fsm.asParameterisedFiniteStateMachine else {
                    return nil
                }
                return Dependency.invokableParameterisedMachine(parameterisedMachine, dependencies)
            case .submachine:
                guard let controllableMachine = fsm.asControllableFiniteStateMachine else {
                    return nil
                }
                return Dependency.submachine(controllableMachine, dependencies)
            }
        }) else {
            return nil
        }
        return (fsm, allDependencies)
    }
    
    fileprivate func createRestrictiveGateway<Gateway: FSMGateway>(forMachine machine: String, gateway: Gateway, dependantMachines: [String], callableMachines: [String], invocableMachines: [String], prefix: String, selfID: FSM_ID, caller: FSM_ID?) -> RestrictiveFSMGateway<Gateway, CallbackFormatter> {
        let format: (String) -> String = {
            if $0 == machine {
                return prefix + "." + machine
            }
            return prefix + "." + machine + "." + $0
        }
        let dependantIds: [FSM_ID] = dependantMachines.map { gateway.id(of: format($0)) }
        let callableIds = callableMachines.map { gateway.id(of: format($0)) }
        let invocableIds = invocableMachines.map { gateway.id(of: format($0)) }
        return RestrictiveFSMGateway(
            gateway: gateway,
            selfID: caller ?? selfID,
            callables: Set(callableIds + [selfID]),
            invocables: Set(invocableIds),
            whitelist: Set(dependantIds + [selfID]),
            formatter: CallbackFormatter(format)
        )
    }

}

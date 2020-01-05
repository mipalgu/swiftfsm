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

#if !NO_FOUNDATION

import FSM
import Libraries
import SwiftMachines
import swiftfsm
import IO
import Gateways
import swift_helpers

@available(macOS 10.11, *)
public final class MachinesMachineLoader: MachineLoader {

    fileprivate typealias SymbolSignature = @convention(c) (Any, Any, Any) -> Any

    fileprivate let compiler: MachineCompiler<MachineAssembler>
    fileprivate let libraryLoader: LibraryMachineLoader
    fileprivate let parser: MachineParser
    fileprivate let printer: Printer

    fileprivate let cCompilerFlags: [String]
    fileprivate let linkerFlags: [String]
    fileprivate let swiftCompilerFlags: [String]
    fileprivate let swiftBuildFlags: [String]

    @available(macOS 10.11, *)
    public init(
        compiler: MachineCompiler<MachineAssembler> = MachineCompiler(assembler: MachineAssembler()),
        libraryLoader: LibraryMachineLoader,
        parser: MachineParser = MachineParser(),
        printer: Printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream()),
        cCompilerFlags: [String] = [],
        linkerFlags: [String] = [],
        swiftCompilerFlags: [String] = [],
        swiftBuildFlags: [String] = []
    ) {
        self.compiler = compiler
        self.libraryLoader = libraryLoader
        self.parser = parser
        self.printer = printer
        self.cCompilerFlags = cCompilerFlags
        self.linkerFlags = linkerFlags
        self.swiftCompilerFlags = swiftCompilerFlags
        self.swiftBuildFlags = swiftBuildFlags
    }

    public func load<Gateway: FSMGateway>(name: String, gateway: Gateway, clock: Timer, path: String) -> (FSMType, [Dependency])? {
        guard let machine = self.parser.parseMachine(atPath: path) else {
            self.parser.errors.forEach(self.printer.error)
            return nil
        }
        return load(machine: machine, gateway: gateway, clock: clock, prefix: name)
    }

    fileprivate func load<Gateway: FSMGateway>(machine: Machine, gateway: Gateway, clock: Timer, prefix: String, caller: FSM_ID? = nil) -> (FSMType, [Dependency])? {
        let dependantMachines = machine.submachines + machine.parameterisedMachines
        let format: (String) -> String = {
            if $0 == machine.name {
                return prefix + "." + machine.name
            }
            return prefix + "." + machine.name + "." + $0
        }
        let selfID: FSM_ID = gateway.id(of: prefix + "." + machine.name)
        let dependantIds: [FSM_ID] = dependantMachines.map { gateway.id(of: format($0.name)) }
        let callableIds = machine.callableMachines.map { gateway.id(of: format($0.name)) }
        let invocableIds = machine.invocableMachines.map { gateway.id(of: format($0.name)) }
        let caller = caller ?? selfID
        let newGateway = RestrictiveFSMGateway(
            gateway: gateway,
            selfID: caller,
            callables: Set(callableIds + [selfID]),
            invocables: Set(invocableIds),
            whitelist: Set(dependantIds + [selfID]),
            formatter: CallbackFormatter(format)
        )
        guard let recursed = dependantMachines.failMap({ (m: Machine) -> Dependency? in
            let id = gateway.id(of: format(m.name))
            let caller = true == callableIds.contains(id) ? caller : id
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
        if false == self.compiler.shouldCompile(machine) {
            let outputPath = self.compiler.outputPath(forMachine: machine)
            guard let fsm = self.loadSymbol(inMachine: machine.name, gateway: newGateway, clock: clock, path: outputPath, caller: caller) else {
                return nil
            }
            return (fsm, recursed)
        }
        guard
            let outputPath = self.compiler.compile(
                machine,
                withCCompilerFlags: self.cCompilerFlags,
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

}

#endif

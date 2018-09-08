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

import FSM
import SwiftMachines
import swiftfsm

@available(macOS 10.11, *)
public final class MachinesMachineLoader: MachineLoader {

    fileprivate let compiler: MachineCompiler<MachineAssembler>
    fileprivate let libraryLoader: MachineLoader
    fileprivate let parser: MachineParser

    fileprivate let cCompilerFlags: [String]
    fileprivate let linkerFlags: [String]
    fileprivate let swiftCompilerFlags: [String]

    @available(macOS 10.11, *)
    public init(
        compiler: MachineCompiler<MachineAssembler> = MachineCompiler(assembler: MachineAssembler()),
        libraryLoader: MachineLoader,
        parser: MachineParser = MachineParser(),
        cCompilerFlags: [String] = [],
        linkerFlags: [String] = [],
        swiftCompilerFlags: [String] = []
    ) {
        self.compiler = compiler
        self.libraryLoader = libraryLoader
        self.parser = parser
        self.cCompilerFlags = cCompilerFlags
        self.linkerFlags = linkerFlags
        self.swiftCompilerFlags = swiftCompilerFlags
    }

    public func load(name: String, invoker: swiftfsm.Invoker, clock: Timer, path: String) -> (AnyScheduleableFiniteStateMachine, [Dependency], Timer)? {
        guard let machine = self.parser.parseMachine(atPath: path) else {
            return nil
        }
        if false == self.compiler.shouldCompile(machine) {
            return self.libraryLoader.load(name: name, invoker: invoker, clock: clock, path: self.compiler.outputPath(forMachine: machine))
        }
        guard
            let outputPath = self.compiler.compile(
                machine,
                withCCompilerFlags: self.cCompilerFlags,
                andLinkerFlags: self.linkerFlags,
                andSwiftCompilerFlags: self.swiftCompilerFlags
            )
        else {
            return nil
        }
        return self.libraryLoader.load(name: name, invoker: invoker, clock: clock, path: outputPath)
    }

}

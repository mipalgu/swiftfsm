/*
 * SwiftfsmBuild.swift
 * swiftfsmc
 *
 * Created by Callum McColl on 12/10/20.
 * Copyright © 2020 Callum McColl. All rights reserved.
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

import IO
import ArgumentParser
import MachineCompiling
import SwiftMachines
import Foundation

extension TargetTriple: ExpressibleByArgument {
    
    public init?(argument: String) {
        self.init(triple: argument)
    }
    
    public var defaultValueDescription: String {
        return "<<arch><subarch>-<vendor>-<os>-<environment>>"
    }
    
}

extension SwiftBuildConfig: ExpressibleByArgument {
    
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
    
}

@available(macOS 10.11, *)
struct SwiftfsmBuild: ParsableCommand {
    
    static let configuration = CommandConfiguration(commandName: "swiftfsm-build", abstract: "Generate and compile a swiftfsm arrangement.")
    
    @Option(name: .customShort("o"), help: "Path to the resulting arrangment directory.")
    public var arrangmentPath: String
    
    public var executableName: String? {
        guard let executable = self.arrangmentPath.components(separatedBy: ".").first else {
            return nil
        }
        let trimmed = executable.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return nil
        }
        return trimmed
    }
    
    @Option(name: .short, help: "Specify the swift build config")
    public var config: SwiftBuildConfig = .debug
    
    @Option(name: .customLong("target", withSingleDash: true), help: "Specify an LLVM triple to cross-compile for.")
    public var target: TargetTriple?
    
    @Option(wrappedValue: nil, name: .shortAndLong, help: "Force a specific machine build directory name.", transform: { $0.isEmpty ? nil : $0 })
    public var buildDir: String?

    /**
     * Flags passed to the C compiler when compiling a machine.
     */
    @Option(name: .customLong("Xcc", withSingleDash: true), parsing: .unconditionalSingleValue, help: "Pass a compiler flag to the C compiler when compiling this machine.")
    public var cCompilerFlags: [String] = []

    @Option(name: .customLong("Xcxx", withSingleDash: true), parsing: .unconditionalSingleValue, help: "Pass a compiler flag to the C++ compiler when compiling this machine.")
    public var cxxCompilerFlags: [String] = []

    /**
     * Flags which are passed to the linker when compiling a machine.
     */
    @Option(name: .customLong("Xlinker", withSingleDash: true), parsing: .unconditionalSingleValue, help: "Pass a linker flag to the linker when compiling this machine.")
    public var linkerFlags: [String] = []

    /**
     * Flags passed to the swift compiler when compiling a machine.
     */
    @Option(name: .customLong("Xswiftc", withSingleDash: true), parsing: .unconditionalSingleValue, help: "Pass a compiler flag to the swift compiler when compiling this machine.")
    public var swiftCompilerFlags: [String] = []

    @Option(name: .customLong("Xswiftbuild", withSingleDash: true), parsing: .unconditionalSingleValue, help: "Pass a flag to swift build when compiling this machine.")
    public var swiftBuildFlags: [String] = []

    /**
     *  The path to load the `Machine`.
     */
    @Argument(help: "Paths to the machines in the arrangement.")
    public var paths: [String]
    
    public var actualBuildDir: String {
        if let buildDir = buildDir {
            return buildDir
        }
        if let target = target {
            let os = target.os.rawValue
            let arch = target.rawArch ?? target.arch.rawValue
            return os + "-" + arch
        }
        var uts = utsname()
        guard
            0 == uname(&uts),
            let sysname = withUnsafePointer(to: &uts.sysname.0, { String(validatingUTF8: $0) }),
            let machine = withUnsafePointer(to: &uts.machine.0, { String(validatingUTF8: $0) })
        else {
            return ".build"
        }
        return sysname + "-" + machine
    }
    
    func run() throws {
        let printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())
        let buildDir = self.actualBuildDir
        let compiler = MachineArrangementCompiler()
        let parser = MachineParser()
        // Parse machines
        guard let machines = self.paths.failMap({ parser.parseMachine(atPath: $0) }) else {
            parser.errors.forEach {
                print($0, stderr)
            }
            printer.error(str: "Unable to parse machines")
            throw ExitCode.failure
        }
        guard let executableName = self.executableName else {
            throw ValidationError("Cannot calcualte executable name from arrangement path: " + self.arrangmentPath)
        }
        // Compile the arrangement.
        guard nil != compiler.compileArrangement(
            arrangement: machines,
            executableName: executableName,
            withBuildDir: URL(fileURLWithPath: self.arrangmentPath, isDirectory: true),
            machineBuildDir: buildDir,
            swiftBuildConfig: self.config,
            withCCompilerFlags: self.cCompilerFlags,
            andCXXCompilerFlags: self.cxxCompilerFlags,
            andLinkerFlags: self.linkerFlags,
            andSwiftCompilerFlags: self.swiftCompilerFlags,
            andSwiftBuildFlags: self.swiftBuildFlags
        ) else {
            compiler.errors.forEach {
                printer.error(str: $0)
            }
            printer.error(str: "Unable to compile the arrangement package")
            throw ExitCode.failure
        }
    }
    
}

/*
 * SwiftfsmClean.swift
 * swiftfsm_binaries
 *
 * Created by Callum McColl on 27/10/20.
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

import MachineCompiling
import IO
import ArgumentParser
import SwiftMachines
import Foundation

public struct SwiftfsmClean: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "clean", _superCommandName: "swiftfsm", abstract: "Clean a swift arrangement build.")
    
    @Argument(help: ArgumentHelp("The path to the arrangement.", valueName: "directory.arrangement"))
    public var arrangement: String
    
    @Flag(help: "Also clean the machine hierarchy.")
    public var all: Bool = false
    
    @Option(
        name: .customLong("target", withSingleDash: true),
        help: ArgumentHelp(
            "Specify an LLVM triple to clean for.",
            discussion: """
                The triple is composed of several fields in the format <arch><subarch>-<vendor>-<os>-<environment>:
                    <arch>: The target architecture (e.g. arm, arm64, i386, x86_64).
                    <subarch>: The target sub-architecture. This is only required
                               for certain <arch> values (e.g. arm64v8).
                    <vendor>: The target vendor (e.g. aldebaran, apple, pc, nvidia).
                    <os>: The target operating system (e.g. darwin, linux, cuda).
                    <environment>: The target environment (e.g. gnu, msvc, android,
                                   macabi, simulator).
                """,
            valueName: "triple"
        )
    )
    public var target: TargetTriple?
    
    @Option(
        wrappedValue: nil,
        name: .shortAndLong,
        help: ArgumentHelp(
            "Force a specific machine build directory name when cleaning the hierarchy.",
            discussion: "For each machine in the arrangement, will clean swift packages in <machine>.machine/<build-dir>.",
            valueName: "build-dir"
        ),
        transform: { $0.isEmpty ? nil : $0 }
    )
    public var buildDir: String?
    
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
    
    public init() {}
    
    public func run() throws {
        let printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())
        let url = URL(fileURLWithPath: arrangement, isDirectory: true)
        let fm = FileManager.default
        let buildDir = url.appendingPathComponent(".build", isDirectory: true).path
        printer.message(str: "Removing " + buildDir)
        do {
            try fm.removeItem(atPath: buildDir)
        } catch let e as NSError {
            if e.code != NSFileNoSuchFileError {
                printer.error(str: "\(e)")
                throw ExitCode.failure
            }
        }
        if false == self.all {
            return
        }
        let parser = MachineArrangementParser()
        guard let arrangement = parser.parseArrangement(atDirectory: URL(fileURLWithPath: arrangement, isDirectory: true)) else {
            parser.errors.forEach(printer.error)
            throw ExitCode.failure
        }
        do {
            try clean(arrangement: arrangement, buildDir: actualBuildDir, printer: printer)
        } catch let e {
            printer.error(str: "\(e)")
            throw ExitCode.failure
        }
    }
    
    private func clean<P: Printer>(arrangement: Arrangement, buildDir: String, printer: P) throws {
        let fm = FileManager.default
        var processed: Set<URL> = []
        func _process(_ dependency: Machine.Dependency) throws {
            if processed.contains(dependency.filePath) {
                return
            }
            processed.insert(dependency.filePath)
            let buildDir = dependency.filePath.appendingPathComponent(buildDir, isDirectory: true).path
            printer.message(str: "Removing " + buildDir)
            do {
                try fm.removeItem(atPath: buildDir)
            } catch let e as NSError {
                if e.code != NSFileNoSuchFileError {
                    throw CleanError.error(message: e.localizedDescription)
                }
            }
            try dependency.machine.dependencies.forEach(_process)
        }
        try arrangement.dependencies.forEach(_process)
    }
    
    private enum CleanError: Error {
        
        case error(message: String)
        
    }
    
}

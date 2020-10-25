/*
 * SwiftfsmRun.swift
 * swiftfsm-run
 *
 * Created by Callum McColl on 16/10/20.
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

public struct SwiftfsmRun: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "run", _superCommandName: "swiftfsm", abstract: "Execute an arrangement of swiftfsm machines.")
    
    @Option(name: .short, help: ArgumentHelp("Specify which build to execute.", valueName: "config"))
    public var config: SwiftBuildConfig?
    
    @OptionGroup public var swiftfsmArgs: RunArguments
    
    /**
     *  The path to load the `Machine`.
     */
    @Argument(help: ArgumentHelp("The path to the arrangement being executed.", valueName: "directory.arrangement"))
    public var arrangement: String
    
    public init() {}
    
    private var executable: URL? {
        let arrangementDir = URL(fileURLWithPath: arrangement, isDirectory: true)
        let fileName = arrangementDir.lastPathComponent
        guard let executeableName = fileName.components(separatedBy: ".").first else {
            return nil
        }
        if let config = config {
            guard let url = self.executeablePath(named: executeableName, in: arrangementDir, forConfig: config) else {
                return nil
            }
            return url
        }
        for config in SwiftBuildConfig.allCases.reversed() {
            if let url = self.executeablePath(named: executeableName, in: arrangementDir, forConfig: config) {
                return url
            }
        }
        return nil
    }
    
    private func executeablePath(named executeableName: String, in arrangementDir: URL, forConfig config: SwiftBuildConfig) -> URL? {
        let executeableURL: URL
        if #available(macOS 10.11, *) {
            let compiler = MachineArrangementCompiler()
            executeableURL = compiler.outputURL(forArrangement: arrangementDir, executableName: executeableName, swiftBuildConfig: config, libExtension: TargetTriple.platform?.sharedObjectExtension ?? "so")
        } else {
            executeableURL = arrangementDir
                .appendingPathComponent(".build", isDirectory: true)
                .appendingPathComponent(config.rawValue, isDirectory: true)
                .appendingPathComponent(executeableName, isDirectory: false)
        }
        let fm = FileManager.default
        guard fm.fileExists(atPath: executeableURL.path) else {
            return nil
        }
        return executeableURL
    }
    
    public func run() throws {
        let printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())
        guard let executable = self.executable else {
            printer.error(str: "Unable to load executable of arrangement.")
            throw ExitCode.failure
        }
        var args: [String] = []
        if swiftfsmArgs.debug {
            args.append("-d")
        }
        args.append("-s")
        switch swiftfsmArgs.scheduler {
        case .roundRobin:
            args.append("rr")
        case .passiveRoundRobin:
            args.append("prr")
        case .timeTriggered(let dispatchTable):
            args.append(dispatchTable)
        }
        let invoker = Invoker()
        guard invoker.run(executable.path, withArguments: args) else {
            throw ExitCode.failure
        }
    }
    
}

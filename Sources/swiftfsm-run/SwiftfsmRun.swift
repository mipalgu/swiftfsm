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
import swiftfsm_binaries

extension SwiftBuildConfig: ExpressibleByArgument {
    
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
    
}

struct SwiftfsmRun: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Execute an arrangement of swiftfsm machines.")
    
    @Option(name: .short, help: "Specify which build to execute.")
    public var config: SwiftBuildConfig?
    
    @OptionGroup public var swiftfsmArgs: RunArguments
    
    /**
     *  The path to load the `Machine`.
     */
    @Argument(help: "The path to the arrangement.")
    public var arrangement: String
    
    private var executable: URL? {
        let printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())
        let fm = FileManager.default
        let arrangementDir = URL(fileURLWithPath: arrangement, isDirectory: true)
        let fileName = arrangementDir.lastPathComponent
        guard let executeableName = fileName.components(separatedBy: ".").first else {
            printer.error(str: "Unable to calculate the executable name from the arrangment.")
            return nil
        }
        if let config = config {
            let executablePath = arrangementDir.appendingPathComponent(config.rawValue, isDirectory: true).appendingPathComponent(executeableName, isDirectory: false)
            guard fm.fileExists(atPath: executablePath.path) else {
                printer.error(str: "Unable to find executable at path: " + executablePath.path)
                return nil
            }
            return executablePath
        }
        for config in SwiftBuildConfig.allCases.reversed() {
            let path = arrangementDir.appendingPathComponent(config.rawValue, isDirectory: true).appendingPathComponent(executeableName, isDirectory: false)
            if true == fm.fileExists(atPath: path.path) {
                return path
            }
        }
        return nil
    }
    
    func run() throws {
        guard let executable = self.executable else {
            throw ExitCode.failure
        }
        var args: [String] = []
        if swiftfsmArgs.debug {
            args.append("-d")
        }
        switch swiftfsmArgs.scheduler {
        case .roundRobin:
            args.append("-rr")
        case .passiveRoundRobin:
            args.append("-prr")
        }
        if let dispatchTable = swiftfsmArgs.dispatchTable {
            args.append("-S")
            args.append(dispatchTable)
        }
        let invoker = Invoker()
        guard invoker.run(executable.path, withArguments: args) else {
            throw ExitCode.failure
        }
    }
    
}

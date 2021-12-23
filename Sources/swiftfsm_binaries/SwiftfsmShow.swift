/*
 * SwiftfsmShow.swift
 * swiftfsm_binaries
 *
 * Created by Callum McColl on 18/10/20.
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
import SwiftMachines
import Foundation

public struct SwiftfsmShow: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "show", _superCommandName: "swiftfsm", abstract: "Displays a list of machines in an arrangement.")
    
    @Flag(help: "Show the entire machine hierarchy.")
    public var all: Bool = false
    
    /**
     *  The path to load the `Machine`.
     */
    @Argument(help: ArgumentHelp("The path to the arrangement.", valueName: "directory.arrangement"))
    public var arrangement: String
    
    public init() {}
    
    public func run() throws {
        let printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())
        let parser = MachineArrangementParser()
        let url = URL(fileURLWithPath: arrangement, isDirectory: true)
        guard let arrangement = parser.parseArrangement(atDirectory: url) else {
            parser.errors.forEach(printer.error)
            throw ExitCode.failure
        }
        let str: String
        if false == all {
            str = arrangement.dependencies.map { ($0.name ?? $0.machineName) + " -> " + $0.filePath(relativeTo: url).path }.joined(separator: "\n")
        } else {
            str = self.hierarchy(of: arrangement, atDirectory: url)
        }
        printer.message(str: str)
    }
    
    private func hierarchy(of arrangement: Arrangement, atDirectory url: URL) -> String {
        func process(_ dependency: Machine.Dependency, parent: URL, prefix: String = "", indent: String = "") -> String {
            let name = (dependency.name ?? dependency.machineName)
            let str = indent + prefix + name + " -> " + dependency.filePath(relativeTo: parent).path
            let deps = dependency.machine(relativeTo: parent).dependencies.map {
                process($0, parent: dependency.filePath(relativeTo: parent), prefix: name + ".", indent: indent + "    ")
            }.joined(separator: "\n")
            let spacing = deps.isEmpty ? "" : "\n"
            if deps.isEmpty {
                return str + spacing
            }
            return str + "\n" + deps + spacing
        }
        return arrangement.dependencies.map { process($0, parent: url) }.joined(separator: "\n")
    }
    
}

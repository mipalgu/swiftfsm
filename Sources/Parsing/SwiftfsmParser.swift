/*
 * SwiftfsmParser.swift
 * swiftfsm
 *
 * Created by Callum McColl on 15/12/2015.
 * Copyright © 2015 Callum McColl. All rights reserved.
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
import Scheduling
import Verification

/**
 *  The standard `Parser`.
 */
public class SwiftfsmParser: HelpableParser {
    
    public var helpText: String {
        var str: String = "OVERVIEW: A Finite State Machine Scheduler\n\n"
        str += "USAGE: swiftfsm [options] <machine_path> ...\n\n"
        str += "OPTIONS:\n"
        str += "\t-c\t\tCompile the machine.\n"
        str += "\t-d, --debug\tEnables debugging.\n"
        str += "\t-h, --help\tPrint this help message.\n"
        str += "\t-k [-r|--run], --kripke [-r|--run]\n"
        str += "\t\t\tGenerate the Kripke Structure for the machine.\n"
        str += "\t\t\tNote: Optionally specify -r or --run to schedule the machine to run as well as generate the kripke structure.\n"
        str += "\t-l, --clfsm\tSpecifies that this is a machine that has been built using the CLFSM specification.\n"
        str += "\t-n <value>, --name <value>\n"
        str += "\t\t\tSpecify a name for the machine.\n"
        str += "\t-s <rr|prr>, --scheduler <RoundRobin|PassiveRoundRobin>\n"
        str += "\t\t\tSpecify which scheduler to use.  Defaults to a round robin scheduler.\n"
        str += "\t-x <value>, --repeat <value>\n"
        str += "\t\t\tSpecify number of times to repeat this command\n"
        str += "\t-Xcc <value>\tPass a compiler flag to the C compiler when compiling the machine.\n"
        str += "\t-Xlinker <value>\n"
        str += "\t\t\tPass a linker flag to the linker when compiling the machine.\n"
        str += "\t-Xswiftc <value>\n"
        str += "\t\t\tPass a compiler flag to the swift compiler when compiling the machine.\n"
        return str
    }

    fileprivate let passiveRoundRobinFactory: PassiveRoundRobinSchedulerFactory

    fileprivate let roundRobinFactory: RoundRobinSchedulerFactory

    public init(passiveRoundRobinFactory: PassiveRoundRobinSchedulerFactory, roundRobinFactory: RoundRobinSchedulerFactory) {
        self.passiveRoundRobinFactory = passiveRoundRobinFactory
        self.roundRobinFactory = roundRobinFactory
    }
    
    /**
     *  Parse the command line arguments and create new `Task`s.
     *
     *  - Parameter words: The command line arguments.
     *
     *  - Returns: An array of `Task`s that were created based on the command
     *  line arguments.
     */
    public func parse(words: [String]) throws -> [Task] {
        var wds: [String] = words
        var tasks: [Task] = []
        let t: Task = Task()
        tasks.append(t)
        // Keep looping while we still have input
        while (false == wds.isEmpty) {
            tasks[tasks.count - 1] = try self.handleNextFlag(
                tasks[tasks.count - 1],
                words: &wds
            )
            // Remove words that we are finished with
            wds.removeFirst()
            // Only create a new task if we have found the path to the current
            // task and we have more words to come.
            if (nil == tasks[tasks.count - 1].path || true == wds.isEmpty) {
                continue
            }
            var newTask = Task()
            newTask.generateKripkeStructure = tasks.last?.generateKripkeStructure ?? false
            newTask.addToScheduler = tasks.last?.addToScheduler ?? true
            newTask.kripkeStructureViews = tasks.last?.kripkeStructureViews
            newTask.scheduler = tasks.last?.scheduler
            tasks.append(newTask)
        }
        return tasks
    }
    
    private func handleNextFlag(_ t: Task, words: inout [String]) throws -> Task {
        switch (words.first!) {
        case "-c":
            return self.handleCompileFlag(t, words: &words)
        case "-d", "--debug":
            return self.handleDebugFlag(t, words: &words)
        case "-h", "--help":
            return self.handleHelpFlag(t, words: &words)
        case "-k", "--kripke":
            return try self.handleKripkeFlag(t, words: &words)
        case "-l", "--clfsm":
            return self.handleClfsmFlag(t, words: &words)
        case "-n", "--name":
            return self.handleNameFlag(t, words: &words)
        case "-s", "--scheduler":
            return try self.handleSchedulerFlag(t, words: &words)
        case "-x", "--repeat":
            return self.handleRepeatFlag(t, words: &words)
        case "-Xcc":
            return self.handleCCompilerFlag(t, words: &words)
        case "-Xlinker":
            return self.handleLinkerFlag(t, words: &words)
        case "-Xswiftc":
            return self.handleSwiftCompilerFlag(t, words: &words)
        default:
            return try self.handlePath(t, words: &words)
        }
    }

    private func fetchValueAfterFlag(_ t: Task, words: inout [String]) -> String? {
        if (words.count < 2) {
            return nil
        }
        let n: String = words[1]
        // Ignore empty strings as names
        if (true == n.characters.isEmpty) {
            words.removeFirst()
            return nil
        }
        // Ignore other flags if the user forgets to enter a name after the name
        // flag.
        if ("-" == n.characters.first!) {
            return nil
        }
        words.removeFirst()
        return words.first!
    }
    
    private func handleDebugFlag(_ t: Task, words: inout [String]) -> Task {
        var temp: Task = t
        temp.enableDebugging = true
        return temp
    }
    
    private func handleHelpFlag(_ t: Task, words: inout [String]) -> Task {
        var temp: Task = t
        temp.printHelpText = true
        return temp
    }
    
    private func handleKripkeFlag(_ t: Task, words: inout [String]) throws -> Task {
        if true == t.generateKripkeStructure {
            throw ParsingErrors.generalError(error: "You can only specify the -k option once.")
        }
        var temp: Task = t
        temp.generateKripkeStructure = true
        temp.addToScheduler = false
        while words.count > 1 {
            switch words[1] {
            case "-o":
                if words.count < 3 {
                    throw ParsingErrors.generalError(error: "No value for Kripke Structure output flag.")
                }
                temp.kripkeStructureViews = try words[2].compactMap(self.convertCharToView)
            case "-r", "--run":
                temp.addToScheduler = true
                words.removeFirst()
            default:
                break
            }
        }
        return temp
    }
    
    private func convertCharToView(_ c: Character) throws -> KripkeStructureView? {
        switch c {
        case "n":
            return NuSMVKripkeStructureView(factory: FilePrinterFactory())
        case "g":
            return GraphVizKripkeStructureView(factory: FilePrinterFactory())
        default:
            throw ParsingErrors.generalError(error: "Unknown value for Kripke Structure output flag.")
        }
    }
    
    private func handleNameFlag(_ t: Task, words: inout [String]) -> Task {
        guard let name = self.fetchValueAfterFlag(t, words: &words) else {
            return t
        }
        var temp: Task = t
        temp.name = name
        return temp
    }
    
    private func handleClfsmFlag(_ t: Task, words: inout [String]) -> Task {
        var temp: Task = t
        temp.isClfsmMachine = true
        return temp
    }

    private func handleCCompilerFlag(_ t: Task, words: inout [String]) -> Task {
        guard let arg = self.fetchValueAfterFlag(t, words: &words) else {
            return t
        }
        var temp: Task = t
        temp.cCompilerFlags.append(arg)
        return temp
    }

    
    private func handleCompileFlag(_ t: Task, words: inout [String]) -> Task {
        var temp: Task = t
        temp.compile = true
        return temp
    }

    private func handleLinkerFlag(_ t: Task, words: inout [String]) -> Task {
        guard let arg = self.fetchValueAfterFlag(t, words: &words) else {
            return t
        }
        var temp: Task = t
        temp.linkerFlags.append(arg)
        return temp
    }

    private func handleSwiftCompilerFlag(_ t: Task, words: inout [String]) -> Task {
        guard let arg = self.fetchValueAfterFlag(t, words: &words) else {
            return t
        }
        var temp: Task = t
        temp.swiftCompilerFlags.append(arg)
        return temp
    }

    private func handleSchedulerFlag(_ t: Task, words: inout [String]) throws -> Task {
        if nil != t.scheduler {
            throw ParsingErrors.generalError(error: "You can only specify the -s option once.")
        }
        guard let scheduler = self.fetchValueAfterFlag(t, words: &words) else {
            return t
        }
        switch scheduler {
        case "rr", "RoundRobin":
            print("Using Round Robin Scheduler")
            var temp: Task = t
            temp.scheduler = .roundRobin(self.roundRobinFactory, RoundRobinKripkeStructureGeneratorFactory()) 
            return temp
        case "prr", "PassiveRoundRobin":
            print("Using Passive Scheduler")
            var temp: Task = t
            temp.scheduler = .passiveRoundRobin(self.passiveRoundRobinFactory, PassiveRoundRobinKripkeStructureGeneratorFactory())
            return temp
        default:
            throw ParsingErrors.generalError(error: "Unknown value for scheduler flag")
        }
    }
    
    private func handlePath(_ t: Task, words: inout [String]) throws -> Task {
        // Ignore empty strings
        if (true == words.first!.isEmpty) {
            return t
        }
        // Ignore unknown flags
        if ("-" == words.first!.characters.first) {
            throw ParsingErrors.unknownFlag(flag: words.first!)
        }
        var temp: Task = t
        temp.path = words.first!
        return temp
    }

    private func handleRepeatFlag(_ t: Task, words: inout [String]) -> Task {
        guard
            let numStr = self.fetchValueAfterFlag(t, words: &words),
            let num: Int = Int(numStr),
            num >= 0
        else {
            return t
        }
        var temp: Task = t
        temp.count = num
        return temp
    }
    
}

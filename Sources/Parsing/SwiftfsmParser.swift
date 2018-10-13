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
        return """
        OVERVIEW: A Finite State Machine Scheduler.
        
        USAGE: swiftfsm [options] ([machine_options] <machine_path>)...
        
        OPTIONS:
                -d, --debug     Enables debugging.
                -h, --help      Print this help message.
                -g, --generate-schedule-map
                                Generates a scheduler map file. This file is
                                used by the scheduler to determine when to run
                                each finite state machine.
                -k|--kripke [-o|--output <gntx>...] [-r|--run]
                                Generate the Kripke Structures for all machines.
                                Note: Optionally use -o or --output tp specify 1
                                or more output fromats for the Kripke
                                Structures. The default is a single NuSMV
                                file (n).
                                Available Formats:
                                    g: GraphViz dot format. Outputs
                                       kripke_structure.gv.
                                    n: NuSMV format. Outputs main.smv.
                                    t: Tulip format. Used by the Tulip graph
                                       visualiser. Outputs kripke_structure.tlp.
                                    x: Gexf format. Used by the Gephi graph
                                       visualiser. Outputs
                                       kripke_structure.gexf.
                                Note: Optionally specify -r or --run to
                                schedule the machines to run after generating
                                the Kripke Structures.
                -s <rr|prr>, --scheduler <RoundRobin|PassiveRoundRobin>
                                Specify which scheduler to use. Default to a
                                round-robin scheduler (rr).
                                Available Schedulers:
                                    prr: Passive Round-Robin. Takes a snapshot
                                         of the external variables before
                                         executing each entire schedule cycle.
                                         The snapshot is saved at the end of
                                         each schedule cycle, after all LLFSMs
                                         have executed a single ringlet.
                                     rr: Round-Robin. Takes a snapshot of the
                                         external variables before executing
                                         each ringlet in each LLFSM. The
                                         snapshot is saved after executing each
                                         ringlet in each LLFSM.
        
        MACHINE OPTIONS:
                -c              Compile this machine.
                -l, --clfsm
                                Specifies that this is a machine that has been
                                built using the CLFSM specification.
                -n <value>, --name <value>
                                Specify a name for this machine.
                -x <value>, --repeat <value>
                                Specify number of times to schedule this
                                machine. This flag allows the creation of more
                                than a single instance of a particular machine.
                                Each instance will have a unique name and be
                                treated as a separate machine for the purposes
                                of scheduling.
                -Xcc <value>
                                Pass a compiler flag to the C compiler when
                                compiling this machine.
                -Xlinker <value>
                                Pass a linker flag to the linker when compiling
                                this machine.
                -Xswiftc <value>
                                Pass a compiler flag to the swift compiler when
                                compiling this machine.
        """
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
    public func parse(words: [String]) throws -> Task {
        var wds: [String] = words
        var task = try self.parseTask(words: &wds)
        var jobs: [Job] = []
        jobs.append(Job())
        // Keep looping while we still have input
        while (false == wds.isEmpty) {
            jobs[jobs.count - 1] = try self.handleNextFlag(
                jobs[jobs.count - 1],
                words: &wds
            )
            // Remove words that we are finished with
            wds.removeFirst()
            // Only create a new task if we have found the path to the current
            // task and we have more words to come.
            if (nil == jobs[jobs.count - 1].path || true == wds.isEmpty) {
                continue
            }
            jobs.append(Job())
        }
        task.jobs = jobs
        if nil == task.jobs[0].path && false == task.printHelpText {
            throw ParsingErrors.noPathsFound
        }
        return task
    }
    
    private func parseTask(words: inout [String]) throws -> Task {
        var task = Task()
        while let str = words.first {
            switch str {
            case "-d", "--debug":
                task = self.handleDebugFlag(task, words: &words)
            case "-g", "--generate-scheduler-map":
                task = self.handleGenerateSchedulerMapFlag(task, words: &words)
            case "-h", "--help":
                task = self.handleHelpFlag(task, words: &words)
            case "-k", "--kripke":
                try task = self.handleKripkeFlag(task, words: &words)
            case "-s", "--scheduler":
                try task = self.handleSchedulerFlag(task, words: &words)
            default:
                return task
            }
            words.removeFirst()
        }
        return task
    }
    
    private func handleNextFlag(_ j: Job, words: inout [String]) throws -> Job {
        switch (words.first!) {
        case "-c":
            return self.handleCompileFlag(j, words: &words)
        case "-l", "--clfsm":
            return self.handleClfsmFlag(j, words: &words)
        case "-n", "--name":
            return self.handleNameFlag(j, words: &words)
        case "-x", "--repeat":
            return self.handleRepeatFlag(j, words: &words)
        case "-Xcc":
            return self.handleCCompilerFlag(j, words: &words)
        case "-Xlinker":
            return self.handleLinkerFlag(j, words: &words)
        case "-Xswiftc":
            return self.handleSwiftCompilerFlag(j, words: &words)
        default:
            return try self.handlePath(j, words: &words)
        }
    }

    private func fetchValueAfterFlag(words: inout [String]) -> String? {
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
    
    private func handleGenerateSchedulerMapFlag(_ t: Task, words: inout [String]) -> Task {
        var temp = t
        temp.generateSchedulerMap = true
        temp.addToScheduler = false
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
            case "-o", "--output":
                if words.count < 3 {
                    throw ParsingErrors.generalError(error: "No value for Kripke Structure output flag.")
                }
                temp.kripkeStructureViews = try words[2].map(self.convertCharToView)
                if true == temp.kripkeStructureViews?.isEmpty {
                    throw ParsingErrors.generalError(error: "No valid values for Kripke Structure output flag.")
                }
                words.removeFirst()
            case "-r", "--run":
                temp.addToScheduler = true
            default:
                return temp
            }
            words.removeFirst()
        }
        return temp
    }
    
    private func convertCharToView(_ c: Character) throws -> KripkeStructureView {
        switch c {
        case "g":
            return GraphVizKripkeStructureView(factory: FilePrinterFactory())
        case "n":
            return NuSMVKripkeStructureView(factory: FileOutputStreamFactory())
        case "t":
            return TulipKripkeStructureView(factory: FilePrinterFactory())
        case "x":
            return GexfKripkeStructureView(factory: FilePrinterFactory())
        default:
            throw ParsingErrors.generalError(error: "Unknown value for Kripke Structure output flag.")
        }
    }
    
    private func handleNameFlag(_ j: Job, words: inout [String]) -> Job {
        guard let name = self.fetchValueAfterFlag(words: &words) else {
            return j
        }
        var temp = j
        temp.name = name
        return temp
    }
    
    private func handleClfsmFlag(_ j: Job, words: inout [String]) -> Job {
        var temp = j
        temp.isClfsmMachine = true
        return temp
    }

    private func handleCCompilerFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words) else {
            return j
        }
        var temp = j
        temp.cCompilerFlags.append(arg)
        return temp
    }

    
    private func handleCompileFlag(_ j: Job, words: inout [String]) -> Job {
        var temp = j
        temp.compile = true
        return temp
    }

    private func handleLinkerFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words) else {
            return j
        }
        var temp = j
        temp.linkerFlags.append(arg)
        return temp
    }

    private func handleSwiftCompilerFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words) else {
            return j
        }
        var temp = j
        temp.swiftCompilerFlags.append(arg)
        return temp
    }

    private func handleSchedulerFlag(_ t: Task, words: inout [String]) throws -> Task {
        if nil != t.scheduler {
            throw ParsingErrors.generalError(error: "You can only specify the -s option once.")
        }
        guard let scheduler = self.fetchValueAfterFlag(words: &words) else {
            return t
        }
        switch scheduler {
        case "rr", "RoundRobin":
            var temp: Task = t
            temp.scheduler = .roundRobin(self.roundRobinFactory, RoundRobinKripkeStructureGeneratorFactory()) 
            return temp
        case "prr", "PassiveRoundRobin":
            var temp: Task = t
            temp.scheduler = .passiveRoundRobin(self.passiveRoundRobinFactory, PassiveRoundRobinKripkeStructureGeneratorFactory())
            return temp
        default:
            throw ParsingErrors.generalError(error: "Unknown value for scheduler flag")
        }
    }
    
    private func handlePath(_ j: Job, words: inout [String]) throws -> Job {
        // Ignore empty strings
        if (true == words.first!.isEmpty) {
            return j
        }
        // Ignore unknown flags
        if ("-" == words.first!.characters.first) {
            throw ParsingErrors.unknownFlag(flag: words.first!)
        }
        var temp = j
        temp.path = words.first!
        return temp
    }

    private func handleRepeatFlag(_ j: Job, words: inout [String]) -> Job {
        guard
            let numStr = self.fetchValueAfterFlag(words: &words),
            let num: Int = Int(numStr),
            num >= 0
        else {
            return j
        }
        var temp = j
        temp.count = num
        return temp
    }
    
}

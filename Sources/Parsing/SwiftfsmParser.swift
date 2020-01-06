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

#if os(macOS)
import Darwin
#else
import Glibc
#endif

import IO
import KripkeStructure
import KripkeStructureViews
import ModelChecking
import Scheduling
import Verification

/**
 *  The standard `Parser`.
 */
public class SwiftfsmParser: HelpableParser {

    public var helpText: String {
        return """
        OVERVIEW: A Finite State Machine Scheduler.
        
        USAGE: swiftfsm [options] [--] ([machine_options] <machine_path>)...
        
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
                -c  [-d <value=.build>, --builddir <value=.build>]
                                Compile this machine.
                                Note: Optionally specify a name for the build
                                folder. This folder will be created inside the
                                machine directory and is where the swift package
                                is generated on compiling the machine.
                -l, --clfsm
                                Specifies that this is a machine that has been
                                built using the CLFSM specification.
                -n <value>, --name <value>
                                Specify a name for this machine.
                -p <key>=<value>, --parameter <key>=<value>
                                Specify that the parameter <key> should receive
                                the value <value>.
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
                -Xcxx <value>   Pass a compiler flag to the C++ compiler when
                                compiling this machine.
                -Xlinker <value>
                                Pass a linker flag to the linker when compiling
                                this machine.
                -Xswiftc <value>
                                Pass a compiler flag to the swift compiler when
                                compiling this machine.
                -Xswiftbuild <value>
                                Pass a flag to swift build when compiling
                                this machine.
        """
    }

    fileprivate let passiveRoundRobinFactory: PassiveRoundRobinSchedulerFactory

    fileprivate let roundRobinFactory: RoundRobinSchedulerFactory
    
    fileprivate let timeTriggeredFactory: TimeTriggeredSchedulerFactoryCreator

    public init(
        passiveRoundRobinFactory: PassiveRoundRobinSchedulerFactory,
        roundRobinFactory: RoundRobinSchedulerFactory,
        timeTriggeredFactory: TimeTriggeredSchedulerFactoryCreator
    ) {
        self.passiveRoundRobinFactory = passiveRoundRobinFactory
        self.roundRobinFactory = roundRobinFactory
        self.timeTriggeredFactory = timeTriggeredFactory
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
        print("words: \(words)")
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
            case "-v", "--verbose":
                try task = self.handleVerboseFlag(task, words: &words)
            case "--":
                words.removeFirst()
                return task
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
        case "-p", "--parameter":
            return try self.handleParameterFlag(j, words: &words)
        case "-x", "--repeat":
            return self.handleRepeatFlag(j, words: &words)
        case "-Xcc":
            return self.handleCCompilerFlag(j, words: &words)
        case "-Xcxx":
            return self.handleCXXFlag(j, words: &words)
        case "-Xlinker":
            return self.handleLinkerFlag(j, words: &words)
        case "-Xswiftc":
            return self.handleSwiftCompilerFlag(j, words: &words)
        case "-Xswiftbuild":
            return self.handleSwiftBuildFlag(j, words: &words)
        default:
            return try self.handlePath(j, words: &words)
        }
    }

    private func fetchValueAfterFlag(words: inout [String], ignoreHyphen: Bool = false) -> String? {
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
        if (!ignoreHyphen && "-" == n.characters.first!) {
            return nil
        }
        words.removeFirst()
        return words.first!
    }
    
    private func handleVerboseFlag(_ t: Task, words: inout [String]) -> Task {
        var temp: Task = t
        temp.enableVerbose = true
        VERBOSE = true
        return temp
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
        return temp
    }

    private func handleKripkeFlag(_ t: Task, words: inout [String]) throws -> Task {
        if true == t.generateKripkeStructure {
            throw ParsingErrors.generalError(error: "You can only specify the -k option once.")
        }
        var temp: Task = t
        temp.generateKripkeStructure = true
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
            default:
                return temp
            }
            words.removeFirst()
        }
        return temp
    }

    private func convertCharToView(_ c: Character) throws -> AnyKripkeStructureViewFactory<KripkeState> {
        switch c {
        case "g":
            return AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory<KripkeState>())
        case "n":
            return AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory<KripkeState>())
        case "t":
            throw ParsingErrors.generalError(error: "t view currently Not Implemented")
            //return TulipKripkeStructureView(factory: FilePrinterFactory())
        case "x":
            throw ParsingErrors.generalError(error: "x view currently Not Implemented")
            //return AnyKripkeStructureView(GexfKripkeStructureView<KripkeState>())
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

    private func handleParameterFlag(_ j: Job, words: inout [String]) throws -> Job {
        guard let keyAndValue = self.fetchValueAfterFlag(words: &words) else {
            throw ParsingErrors.generalError(error: "No parameters specified.")
            return j
        }
        var split: [String] = []
        var splitIndex = keyAndValue.startIndex
        var index = keyAndValue.startIndex
        for c in keyAndValue {
            guard "=" == c else {
                index = keyAndValue.index(after: index)
                continue
            }
            split.append(String(keyAndValue[splitIndex..<index]))
            splitIndex = keyAndValue.index(after: index)
            index = splitIndex
        }
        split.append(String(keyAndValue[splitIndex..<keyAndValue.endIndex]))
        split = split.filter { !$0.isEmpty }
        //let split = keyAndValue.split(separator: "=").filter { !$0.isEmpty }
        if split.count > 2 {
            throw ParsingErrors.generalError(error: "Found multiple '=' characters when attempting to parse key and value from a parameter")
        }
        if split.count < 2 {
            throw ParsingErrors.generalError(error: "Did not find a viable key=value pair when attempting to parse a parameter")
        }
        var temp = j
        temp.parameters[String(split[0])] = String(split[1])
        return temp
    }

    private func handleClfsmFlag(_ j: Job, words: inout [String]) -> Job {
        var temp = j
        temp.isClfsmMachine = true
        return temp
    }

    private func handleCCompilerFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words, ignoreHyphen: true) else {
            return j
        }
        var temp = j
        temp.cCompilerFlags.append(arg)
        return temp
    }


    private func handleCompileFlag(_ j: Job, words: inout [String]) -> Job {
        var temp = j
        temp.compile = true
        if words.count <= 1 {
            return temp
        }
        switch words[1] {
        case "-d", "--builddir":
            words.removeFirst()
            guard let buildDir = self.fetchValueAfterFlag(words: &words, ignoreHyphen: true) else {
                return temp
            }
            temp.buildDir = buildDir
            return temp
        default:
            return temp
        }
    }
    
    private func handleCXXFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words, ignoreHyphen: true) else {
            return j
        }
        var temp = j
        temp.cxxCompilerFlags.append(arg)
        return temp
    }

    private func handleLinkerFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words, ignoreHyphen: true) else {
            return j
        }
        var temp = j
        temp.linkerFlags.append(arg)
        return temp
    }

    private func handleSwiftCompilerFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words, ignoreHyphen: true) else {
            return j
        }
        var temp = j
        temp.swiftCompilerFlags.append(arg)
        return temp
    }
    
    private func handleSwiftBuildFlag(_ j: Job, words: inout [String]) -> Job {
        guard let arg = self.fetchValueAfterFlag(words: &words, ignoreHyphen: true) else {
            return j
        }
        var temp = j
        temp.swiftBuildFlags.append(arg)
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
#if canImport(Foundation) && !NO_FOUNDATION
            guard let table = self.parseTable(scheduler) else {
                throw ParsingErrors.generalError(error: "Unable to parse scheduler \(scheduler)")
            }
            var temp: Task = t
            temp.scheduler = .timeTriggered(
                self.timeTriggeredFactory.make(dispatchTable: table),
                RoundRobinKripkeStructureGeneratorFactory()
            )
            return temp
#else
            throw ParsingErrors.generalError(error: "Unrecognised scheduler: \(scheduler).")
#endif
        }
    }
    
#if canImport(Foundation) && !NO_FOUNDATION
    private func parseTable(_ path: String) -> MetaDispatchTable? {
        let parser = MetaDispatchTableParser()
        return parser.parse(atPath: path)
    }
#endif

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

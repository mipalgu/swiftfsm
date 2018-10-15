/*
 * Swiftfsm.swift
 * swiftfsm
 *
 * Created by Callum McColl on 20/12/2015.
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

 #if os(OSX)
 import Darwin
 #elseif os(Linux)
 import Glibc
 #endif

import FSM
import Functional
import KripkeStructure
import MachineStructure
import MachineLoading
import MachineCompiling
import ModelChecking
import Scheduling
import Timers
import Parsing
import Verification
import swiftfsm

/**
 *  Contains the main logic for swiftfsm.
 */
public class Swiftfsm<
    Compiler: MachineCompiler,
    SF: SchedulerFactory,
    MF: MachineFactory,
    KF: KripkeStructureGeneratorFactory
> where KF.View == AggregateKripkeStructureView<KripkeState> {

    private let clfsmMachineLoader: MachineLoader

    private let kripkeStructureGeneratorFactory: KF

    private let kripkeStructureView: AnyKripkeStructureView<KripkeState>

    private var names: [String: Int] = [:]

    private let machineCompiler: Compiler

    private let machineFactory: MF

    private let machineLoader: MachineLoader

    private let parser: HelpableParser

    private let schedulerFactory: SF

    private let view: View

    /**
     *  Create a new `Swiftfsm`.
     *
     *  - Parameter kripkeStructureGeneratorFactory: Used to generate the
     *  `KripkeStructure`.
     *
     *  - Parameter kripkeStructureView: Used when outputting a
     *  `KripkeStructure`.
     *
     *  - Parameter machineFactory: Used to create the `Machine`s.
     *
     *  - Parameter machineLoader: Used to load the `Machine`s from dynamic
     *  libraries.
     *
     *  - Parameter parser: Used to parse the command line arguments.
     *
     *  - Parameter schedulerFactory: Used to create the `Scheduler` so that it
     *  executes the `Machine`s.
     *
     *  - Parameter view: Used to output `SwiftfsmErrors`.
     */
    public init(
        clfsmMachineLoader: MachineLoader,
        kripkeStructureGeneratorFactory: KF,
        kripkeStructureView: AnyKripkeStructureView<KripkeState>,
        machineCompiler: Compiler,
        machineFactory: MF,
        machineLoader: MachineLoader,
        parser: HelpableParser,
        schedulerFactory: SF,
        view: View
    ) {
        self.clfsmMachineLoader = clfsmMachineLoader
        self.kripkeStructureGeneratorFactory = kripkeStructureGeneratorFactory
        self.kripkeStructureView = kripkeStructureView
        self.machineCompiler = machineCompiler
        self.machineFactory = machineFactory
        self.machineLoader = machineLoader
        self.parser = parser
        self.schedulerFactory = schedulerFactory
        self.view = view
    }

    /**
     *  Run everything!
     *
     *  This includes parsing command line arguments, loading machine,
     *  generating `KripkeStructure`s and executing machines within schedulers.
     */
    public func run(args: [String]) {
        // Pad the output
        self.view.message(message: "")
        // Print help when we have no input.
        if args.count < 2 {
            self.view.message(message: parser.helpText)
            self.handleError(SwiftfsmErrors.parsingError(error: .noPathsFound))
        }
        // Parse the args and get a `Task`.
        let task = self.parseArgs(self.cleanArgs(args))
        // Show the help message when there are no tasks.
        if true == task.jobs.isEmpty {
            self.handleMessage(parser.helpText)
        }
        // Has the user asked to turn on debugging?
        DEBUG = task.enableDebugging
        // Has the user said to print the help message?
        if task.printHelpText {
            self.handleMessage(parser.helpText)
        }
        // Run the tasks.
        self.handleJobs(inTask: task)
    }

    private func cleanArgs(_ args: [String]) -> [String] {
        return args[1 ..< args.count].flatMap { (str: String) -> [String] in
            let cs = Array(str.characters)
            if cs.count < 2 || cs.first != "-" {
                return [str]
            }
            if cs[1] == "-" {
                return [str]
            }
            return cs >>- { $0 == "-" ? nil : "-\($0)" }
        }
    }

    private func generateKripkeStructure<KGF: KripkeStructureGeneratorFactory>(
        _ machines: [Machine],
        withGenerator generatorFactory: KGF,
        andViews views: [AnyKripkeStructureView<KripkeState>]
    ) where KGF.View == AggregateKripkeStructureView<KripkeState> {
        if machines.isEmpty {
            return
        }
        let generator = generatorFactory.make(fromMachines: machines, usingView: AggregateKripkeStructureView(views: views))
        generator.generate()
    }

    private func handleError(_ error: SwiftfsmErrors) -> Never {
        self.view.error(error: error)
        exit(EXIT_FAILURE)
    }

    private func handleMessage(_ message: String) -> Never {
        self.view.message(message: message)
        exit(EXIT_SUCCESS)
    }

    private func handleJobs(inTask task: Task) {
        KRIPKE = task.generateKripkeStructure
        let views = task.kripkeStructureViews ?? [self.kripkeStructureView]
        guard let supportedScheduler = task.scheduler else {
            let scheduler = self.schedulerFactory.make()
            let machines: [Machine] = task.jobs.flatMap { self.handleJob($0, invoker: scheduler) }
            self.handleMachines(
                machines,
                task: task,
                generator: self.kripkeStructureGeneratorFactory,
                scheduler: scheduler,
                views: views
            )
            return
        }
        switch supportedScheduler {
        case .roundRobin(let schedulerFactory, let generator):
            let scheduler = schedulerFactory.make()
            let machines: [Machine] = task.jobs.flatMap { self.handleJob($0, invoker: scheduler) }
            self.handleMachines(
                machines,
                task: task,
                generator: generator,
                scheduler: scheduler,
                views: views
            )
        case .passiveRoundRobin(let schedulerFactory, let generator):
            let scheduler = schedulerFactory.make()
            let machines: [Machine] = task.jobs.flatMap { self.handleJob($0, invoker: scheduler) }
            self.handleMachines(
                machines,
                task: task,
                generator: generator,
                scheduler: scheduler,
                views: views
            )
        }
    }
    
    private func handleMachines<KGF: KripkeStructureGeneratorFactory>(
        _ machines: [Machine],
        task: Task,
        generator: KGF,
        scheduler: Scheduler,
        views: [AnyKripkeStructureView<KripkeState>]
    ) where KGF.View == AggregateKripkeStructureView<KripkeState> {
        if task.generateKripkeStructure {
            self.generateKripkeStructure(machines, withGenerator: generator, andViews: views)
        }
        if task.addToScheduler {
            scheduler.run(machines)
        }
    }

    private func getMachinesName(_ job: Job) -> String {
        var name: String = job.name ?? "machine"
        if let count: Int = self.names[name] {
            let temp: String = name
            name += "\(count)"
            self.names[temp]! += 1
        } else {
            self.names[name] = 1
        }
        return name
    }

    private func loadFsm(
        _ job: Job,
        name: String,
        invoker: Invoker
    ) -> (AnyScheduleableFiniteStateMachine, [Dependency], FSMClock) {
        let clock = FSMClock()
        let fsm: (AnyScheduleableFiniteStateMachine, [Dependency])?
        if true == job.isClfsmMachine {
            fsm = self.clfsmMachineLoader.load(name: name, invoker: invoker, clock: clock, path: job.path!)
        } else {
            fsm = self.machineLoader.load(name: name, invoker: invoker, clock: clock, path: job.path!)
        }
        guard let unwrappedFSM = fsm else {
            // Handle when we are unable to load the fsm.
            self.handleError(.unableToLoad(machineName: name, path: job.path!))
        }
        return (unwrappedFSM.0, unwrappedFSM.1, clock)
    }

    private func handleJob(_ job: Job, invoker: Invoker) -> [Machine] {
        var name: String = self.getMachinesName(job)
        // Handle when there is no path in the Task.
        guard let path = job.path else {
            self.handleError(.parsingError(error: .pathNotFound(machineName: name)))
        }
        if true == job.compile {
            guard true == self.machineCompiler.compileMachine(
                atPath: path,
                withCCompilerFlags: job.cCompilerFlags,
                andLinkerFlags: job.linkerFlags,
                andSwiftCompilerFlags: job.swiftCompilerFlags
            ) else {
                self.handleError(.generalError(error: "Unable to compile machine at \(path)"))
            }
        }
        var machines: [Machine] = []
        for _ in 0 ..< job.count {
            // Create the Machine
            let (fsm, dependencies, clock) = self.loadFsm(job, name: name, invoker: invoker)
            let temp: Machine = self.machineFactory.make(
                name: name,
                fsm: fsm,
                dependencies: dependencies,
                debug: DEBUG,
                clock: clock
            )
            machines.append(temp)
            // Generate the next name of the Machine
            name = self.getMachinesName(job)
        }
        return machines
    }

    private func parseArgs(_ args: [String]) -> Task {
        let task: Task
        do {
            task = try parser.parse(words: args)
        } catch(let error as ParsingErrors) {
            self.handleError(.parsingError(error: error))
        } catch {
            exit(EXIT_FAILURE)
        }
        return task
    }

}

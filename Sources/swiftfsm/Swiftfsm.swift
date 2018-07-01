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
import Scheduling
import Parsing
import Verification

/**
 *  Contains the main logic for swiftfsm.
 */
public class Swiftfsm<
    SF: SchedulerFactory,
    MF: MachineFactory,
    KF: KripkeStructureGeneratorFactory
> where KF.Generator.KripkeStructure == KripkeStructure {

    private let clfsmMachineLoader: MachineLoader

    private let kripkeStructureGeneratorFactory: KF

    private let kripkeStructureView: KripkeStructureView

    private var names: [String: Int] = [:]

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
        kripkeStructureView: KripkeStructureView,
        machineFactory: MF,
        machineLoader: MachineLoader,
        parser: HelpableParser,
        schedulerFactory: SF,
        view: View
    ) {
        self.clfsmMachineLoader = clfsmMachineLoader
        self.kripkeStructureGeneratorFactory = kripkeStructureGeneratorFactory
        self.kripkeStructureView = kripkeStructureView
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
        // Parse the args and get a bunch of tasks.
        let tasks: [Task] = self.parseArgs(self.cleanArgs(args))
        // Show the help message when there are no tasks.
        if true == tasks.isEmpty {
            self.handleMessage(parser.helpText)
        }
        // Has the user asked to turn on debugging?
        DEBUG = nil != tasks.lazy.filter { $0.enableDebugging }.first
        // Has the user said to print the help message?
        if nil != tasks.lazy.filter({ true == $0.printHelpText }).first {
            self.handleMessage(parser.helpText)
        }
        // NoPathsFound when there is only one task and it does not have a path
        if 1 == tasks.count && nil == tasks[0].path {
            self.view.message(message: parser.helpText)
            self.handleError(SwiftfsmErrors.parsingError(error: .noPathsFound))
        }
        // Error when more than one scheduler is specified.
        let schedulers = tasks.filter { $0.scheduler != nil }
        if schedulers.count > 1 {
            self.handleError(SwiftfsmErrors.generalError(error: "You cannot define more than 1 scheduler."))
        }
        let scheduler: SchedulerFactory = schedulers.first?.scheduler ?? self.schedulerFactory
        // Run the tasks.
        self.handleTasks(tasks, withScheduler: scheduler)
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

    private func generateKripkeStructure(_ machines: [Machine]) {
        let generator = self.kripkeStructureGeneratorFactory.make(fromMachines: machines)
        let structure = generator.generate()
        self.kripkeStructureView.make(structure: structure)
    }

    private func handleError(_ error: SwiftfsmErrors) -> Never {
        self.view.error(error: error)
        exit(EXIT_FAILURE)
    }

    private func handleMessage(_ message: String) -> Never {
        self.view.message(message: message)
        exit(EXIT_SUCCESS)
    }

    private func handleTasks(_ tasks: [Task], withScheduler factory: SchedulerFactory) {
        let t: [(schedule: [Machine], kripke: [Machine])] = tasks.map {
            self.handleTask($0)
        }
        self.generateKripkeStructure(t.flatMap { $0.kripke })
        self.runMachines(t.flatMap { $0.schedule }, withScheduler: factory)
    }

    private func getMachinesName(_ task: Task) -> String {
        var name: String = task.name ?? "machine"
        if let count: Int = self.names[name] {
            let temp: String = name
            name += "\(count)"
            self.names[temp]! += 1
        } else {
            self.names[name] = 1
        }
        return name
    }

    private func loadFsms(
        _ task: Task,
        name: String
    ) -> [AnyScheduleableFiniteStateMachine] {
        KRIPKE = task.generateKripkeStructure
        let fsms: [AnyScheduleableFiniteStateMachine]
        if true == task.isClfsmMachine {
            fsms = self.clfsmMachineLoader.load(path: task.path!)
        } else {
            fsms = self.machineLoader.load(path: task.path!)
        }
        if fsms.count > 0 {
            return fsms
        }
        // Handle when we are unable to load the fsm.
        self.handleError(.unableToLoad(machineName: name, path: task.path!))
    }

    private func handleTask(_ task: Task) -> ([Machine], [Machine]) {
        var name: String = self.getMachinesName(task)
        // Handle when there is no path in the Task.
        if nil == task.path {
            self.handleError(.parsingError(error: .pathNotFound(machineName: name)))
        }
        var schedule: [Machine] = []
        var kripke: [Machine] = []
        for _ in 0 ..< task.count {
            // Create the Machine
            let temp: Machine = self.machineFactory.make(
                name: name,
                fsms: self.loadFsms(task, name: name),
                debug: task.enableDebugging
            )
            // Remember to generate Kripke Structures.
            if true == task.generateKripkeStructure {
                kripke.append(temp)
            }
            // Remember to add the machine to the scheduler if need be.
            if true == task.addToScheduler {
                schedule.append(temp)
            }
            // Generate the next name of the Machine
            name = self.getMachinesName(task)
        }
        return (schedule, kripke)
    }

    private func parseArgs(_ args: [String]) -> [Task] {
        let tasks: [Task]
        do {
            tasks = try parser.parse(words: args)
        } catch(let error as SwiftfsmErrors) {
            self.handleError(error)
        } catch {
            exit(EXIT_FAILURE)
        }
        return tasks
    }

    private func runMachines(_ machines: [Machine], withScheduler factory: SchedulerFactory) {
        factory.make(machines: machines).run()
    }

}

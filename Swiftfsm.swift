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

public class Swiftfsm<
    SF: SchedulerFactory,
    MF: MachineFactory,
    MachineType: Machine,
    SteppingFactory: SteppingKripkeStructureGeneratorFactory
    where SF.Machines == MachineType,
    MF.Make == MachineType,
    SteppingFactory.M == MachineType
> {

    public typealias KripkeStructureGeneratorFactory =
        MachineKripkeStructureGeneratorFactory<MachineType, SteppingFactory>

    private let kripkeGeneratorFactory: KripkeStructureGeneratorFactory
    
    private let kripkeStructureView: KripkeStructureView

    private var names: [String: Int] = [:]

    private let machineFactory: MF

    private let machineLoader: MachineLoader
    
    private let parser: HelpableParser
    
    private let schedulerFactory: SF
    
    private let view: View
    
    public init(
        kripkeGeneratorFactory: KripkeStructureGeneratorFactory,
        kripkeStructureView: KripkeStructureView,
        machineFactory: MF,
        machineLoader: MachineLoader,
        parser: HelpableParser,
        schedulerFactory: SF,
        view: View
    ) {
        self.kripkeGeneratorFactory = kripkeGeneratorFactory
        self.kripkeStructureView = kripkeStructureView
        self.machineFactory = machineFactory
        self.machineLoader = machineLoader
        self.parser = parser
        self.schedulerFactory = schedulerFactory
        self.view = view
    }
    
    public func run(args: [String]) {
        // Pad the output
        self.view.message(message: "")
        // Print help when we have no input.
        if (args.count < 2) {
            self.view.message(message: parser.helpText)
            self.handleError(SwiftfsmErrors.NoPathsFound)
        }
        print(args)
        print(self.cleanArgs(args))
        // Parse the args and get a bunch of tasks.
        let tasks: [Task] = self.parseArgs(self.cleanArgs(args))
        // Show the help message when there are no tasks.
        if (true == tasks.isEmpty) {
            self.handleMessage(parser.helpText)
        }
        // Has the user asked to turn on debugging?
        DEBUG = false == tasks.filter { $0.enableDebugging }.isEmpty
        // Has the user said to print the help message?
        if let _ = tasks.filter({ true == $0.printHelpText }).first {
            self.handleMessage(parser.helpText)
        }
        // NoPathsFound when there is only one task and it does not have a path
        if (1 == tasks.count && nil == tasks[0].path) {
            self.view.message(message: parser.helpText)
            self.handleError(SwiftfsmErrors.NoPathsFound)
        }
        // Run the tasks.
        self.handleTasks(tasks)
    }

    private func cleanArgs(_ args: [String]) -> [String] {
        return args[1 ..< args.count].flatMap { (str: String) -> [String] in
            let cs = Array(str.characters)
            if (cs.count < 2 || cs.first != "-") {
                return [str]
            }
            if (cs[1] == "-") {
                return [str]
            }
            return cs.filter { $0 != "-" }.map { "-\($0)" }
        }
    }
    
    private func generateKripkeStructure(_ machines: [MachineType]) {
        let generator: KripkeStructureGenerator =
            self.kripkeGeneratorFactory.make(machines: machines)
        let structure: KripkeStructureType = generator.generate()
        self.kripkeStructureView.make(structure: structure)
    }
    
    private func handleError(_ error: SwiftfsmErrors) {
        self.view.error(error: error)
        exit(EXIT_FAILURE)
    }

    private func handleMessage(_ message: String) {
        self.view.message(message: message)
        exit(EXIT_SUCCESS)
    }
    
    private func handleTasks(_ tasks: [Task]) {
        let t: [(schedule: [MachineType], kripke: [MachineType])] = tasks.map {
            self.handleTask($0)
        }
        self.generateKripkeStructure(t.flatMap { $0.kripke })
        self.runMachines(t.flatMap { $0.schedule })
    }

    private func getMachinesName(_ t: Task) -> String {
        var name: String = nil == t.name ? "machine" : t.name!
        if let count: Int = self.names[name] {
            let temp: String = name
            name += "\(count)"
            self.names[temp]! += 1
        } else {
            self.names[name] = 1
        }
        return name
    }

    private func loadFsms(_ t: Task, name: String) -> [FiniteStateMachine] {
        let fsms: [FiniteStateMachine] = self.machineLoader.load(path: t.path!)
        if (fsms.count > 0) {
            return fsms
        }
        // Handle when we are unable to load the fsm.
        self.handleError(.UnableToLoad(machineName: name, path: t.path!))
        return fsms
    }

    private func handleTask(_ t: Task) -> ([MachineType], [MachineType]) {
        var name: String = self.getMachinesName(t)
        // Handle when there is no path in the Task.
        if (nil == t.path) {
            self.handleError(.PathNotFound(machineName: name))
        }
        if (true == t.isClfsmMachine) {
            self.handleError(.CLFSMMachine(machineName: name, path: t.path!))
        }
        var schedule: [MachineType] = []
        var kripke: [MachineType] = []
        for _ in 0 ..< t.count  {
            // Create the Machine
            let temp: MachineType = self.machineFactory.make(
                name: name,
                fsms: self.loadFsms(t, name: name),
                debug: t.enableDebugging
            )
            // Remember to generate Kripke Structures.
            if (true == t.generateKripkeStructure) {
                kripke.append(temp)
            }
            // Remember to add the machine to the scheduler if need be.
            if (true == t.addToScheduler) {
                schedule.append(temp)
            }
            // Generate the next name of the Machine
            name = self.getMachinesName(t)
        }
        return (schedule, kripke) 
    }
    
    private func parseArgs(_ args: [String]) -> [Task] {
        let tasks: [Task]
        do {
            tasks = try parser.parse(words: args)
        } catch(let error as SwiftfsmErrors) {
            self.handleError(error)
            return []
        } catch {
            exit(EXIT_FAILURE)
        }
        return tasks
    }
    
    private func runMachines(_ machines: [MachineType]) {
        self.schedulerFactory.make(machines: machines).run()
    }
    
}

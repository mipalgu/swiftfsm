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

import FSM

public class Swiftfsm {
    
    private let kripkeGeneratorFactory: MachineKripkeStructureGeneratorFactory
    
    private let machineLoader: MachineLoader
    
    private let parser: HelpableParser
    
    private let schedulerFactory: SchedulerFactory
    
    private let view: View
    
    public init(
        kripkeGeneratorFactory: MachineKripkeStructureGeneratorFactory,
        machineLoader: MachineLoader,
        parser: HelpableParser,
        schedulerFactory: SchedulerFactory,
        view: View
    ) {
        self.kripkeGeneratorFactory = kripkeGeneratorFactory
        self.machineLoader = machineLoader
        self.parser = parser
        self.schedulerFactory = schedulerFactory
        self.view = view
    }
    
    public func run(var args: [String]) {
        // Print help when we have no input.
        if (args.count < 2) {
            self.handleMessage(parser.helpText)
        }
        args.removeFirst()
        // Parse the args and get a bunch of tasks.
        let tasks: [Task] = self.parseArgs(args)
        // Show the help message when there are no tasks.
        if (true == tasks.isEmpty) {
            self.handleMessage(parser.helpText)
        }
        // Has the user said to print the help message?
        if let _ = tasks.filter({ true == $0.printHelpText }).first {
            self.handleMessage(parser.helpText)
        }
        // NoPathsFound when there is only one task and it does not have a path
        if (1 == tasks.count && nil == tasks[0].path) {
            self.view.message(parser.helpText)
            self.handleError(SwiftfsmErrors.NoPathsFound)
        }
        // Run the tasks.
        self.runMachines(self.handleTasks(tasks))
    }
    
    private func generateKripkeStructure(machine: Machine) {
        let generator: KripkeStructureGenerator =
            self.kripkeGeneratorFactory.make(machine)
        let structure: KripkeStructureType = generator.generate()
        self.view.message(structure.description)
    }
    
    private func handleError(error: SwiftfsmErrors) {
        self.view.error(error)
        exit(EXIT_FAILURE)
    }
    
    private func handleMessage(message: String) {
        self.view.message(message)
        exit(EXIT_SUCCESS)
    }
    
    private func handleTasks(tasks: [Task]) -> [Machine] {
        var machines: [Machine] = []
        var i: Int = 1
        for t: Task in tasks {
            // Get/Generate Name of the Machine.
            let name: String = nil == t.name ? "machine \(i)" : t.name!
            // Handle when there is no path in the Task.
            if (nil == t.path) {
                self.handleError(SwiftfsmErrors.PathNotFound(machineName: name))
            }
            // Load the FSM.
            let fsm: FiniteStateMachine? = self.machineLoader.load(t.path!)
            if (nil == fsm) {
                // Handle when we are unable to load the fsm.
                self.handleError(
                    SwiftfsmErrors.UnableToLoad(
                        machineName: name,
                        path: t.path!
                    )
                )
            }
            // Create the Machine.
            let m: Machine = SimpleMachine(name: name, fsm: fsm!)
            // Generate Kripke Structures.
            if (true == t.generateKripkeStructure) {
                self.generateKripkeStructure(m)
            }
            // Remember to add the machine to the scheduler if need be.
            if (true == t.addToScheduler) {
                machines.append(m)
            }
            i++
        }
        return machines
    }
    
    private func parseArgs(args: [String]) -> [Task] {
        let tasks: [Task]
        do {
            tasks = try parser.parse(args)
        } catch(let error as SwiftfsmErrors) {
            self.handleError(error)
            return []
        } catch {
            exit(EXIT_FAILURE)
        }
        return tasks
    }
    
    private func runMachines(machines: [Machine]) {
        self.schedulerFactory.make(machines).run()
    }
    
}

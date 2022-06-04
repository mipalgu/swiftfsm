/*
 * SwiftfsmRunner.swift
 * SwiftMachines
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

#if os(macOS)
import Darwin
#else
import Glibc
#endif

import IO
//import CFSMWrappers
import Gateways
import KripkeStructure
import KripkeStructureViews
import Scheduling
import Verification
import MachineStructure
import swiftfsm
import Timers

struct SwiftfsmRunner {
    
    private let printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())
    
    let args: SwiftfsmArguments
    let machines: [(fsm: FSMType, dependencies: [Dependency])]
    let gateway: StackGateway
    let clock: FSMClock
    
    init(args: SwiftfsmArguments, machines: [(FSMType, [Dependency])], gateway: StackGateway, clock: FSMClock) {
        self.args = args
        self.machines = machines
        self.gateway = gateway
        self.clock = clock
    }
    
    func run() {
        if args.showMachines {
            let str = machines.map {
                self.machineHierarchy($0.fsm, dependencies: $0.dependencies)
            }.joined(separator: "\n\n")
            self.printer.message(str: str)
            return
        }
        let machines = self.machines.map { Machine(debug: args.scheduleArgs.debug, name: $0.fsm.name, fsm: $0.fsm, dependencies: $0.dependencies, clock: clock) }
        //let clfsmMachineLoader = CLFSMMachineLoader()
//        switch self.args.scheduleArgs.scheduler {
//        case .roundRobin:
//            let scheduler = RoundRobinSchedulerFactory(gateway: self.gateway, scheduleHandler: clfsmMachineLoader, unloader: clfsmMachineLoader).make()
//            let generatorFactory = RoundRobinKripkeStructureGeneratorFactory(gateway: self.gateway)
//            self.handleMachines(machines: machines, scheduler: scheduler, generatorFactory: generatorFactory)
//        case .passiveRoundRobin:
//            let scheduler = PassiveRoundRobinSchedulerFactory(gateway: self.gateway, scheduleHandler: clfsmMachineLoader, unloader: clfsmMachineLoader).make()
//            let generatorFactory = PassiveRoundRobinKripkeStructureGeneratorFactory(gateway: self.gateway)
//            self.handleMachines(machines: machines, scheduler: scheduler, generatorFactory: generatorFactory)
//        case .timeTriggered(let path):
//            let parser = MetaDispatchTableParser()
//            guard let dispatchTable = parser.parse(atPath: path) else {
//                parser.errors.forEach(printer.error)
//                exit(EXIT_FAILURE)
//            }
//            let scheduler = TimeTriggeredSchedulerFactory(dispatchTable: dispatchTable, gateway: self.gateway, scheduleHandler: clfsmMachineLoader, unloader: clfsmMachineLoader).make()
//            let generatorFactory = TimeTriggeredKripkeStructureGeneratorFactoryCreator(gateway: self.gateway).make(dispatchTable: dispatchTable)
//            self.handleMachines(machines: machines, scheduler: scheduler, generatorFactory: generatorFactory)
//        }
    }
    
    private func machineHierarchy(_ fsm: FSMType, dependencies: [Dependency], indent: String = "") -> String {
        let str = indent + fsm.name
        let deps = dependencies.map {
            machineHierarchy($0.fsm, dependencies: $0.dependencies, indent: indent + "    ")
        }.joined(separator: ",\n")
        if deps.isEmpty {
            return str
        }
        return str + ":\n" + deps
    }
    
//    private func handleMachines<S: Scheduler, F: KripkeStructureGeneratorFactory>(machines: [Machine], scheduler: S, generatorFactory: F) where F.ViewFactory == AggregateKripkeStructureViewFactory<KripkeState> {
//        if self.args.generateKripkeStructures {
//            self.generateKripkeStructure(machines: machines, generatorFactory: generatorFactory, formats: self.args.verifyArgs.formats)
//            return
//        }
//        scheduler.run(machines)
//    }
//    
//    private func generateKripkeStructure<F: KripkeStructureGeneratorFactory>(machines: [Machine], generatorFactory: F, formats: [VerifyArguments.KripkeStructureFormats]) where F.ViewFactory == AggregateKripkeStructureViewFactory<KripkeState> {
//        let formats = formats.isEmpty ? [.nusmv] : formats
//        let viewFactories: [AnyKripkeStructureViewFactory<KripkeState>] = formats.map {
//            switch $0 {
//            case .graphviz:
//                return AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory<KripkeState>())
//            case .nusmv:
//                return AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory<KripkeState>())
//            case .tulip:
//                self.printer.error(str: "Tulip view is currently unsupported.")
//                exit(EXIT_FAILURE)
//            case .gexf:
//                self.printer.error(str: "Gexf view is currently unsupported.")
//                exit(EXIT_FAILURE)
//            }
//        }
//        let generator = generatorFactory.make(fromMachines: machines, usingViewFactory: AggregateKripkeStructureViewFactory(views: viewFactories))
//        generator.generate(usingGateway: gateway)
//    }
}

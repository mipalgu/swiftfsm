/*
 * Swiftfsm.swift
 * swiftfsm_binaries
 *
 * Created by Callum McColl on 12/10/20.
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
import CFSMWrappers
import Gateways
import KripkeStructure
import KripkeStructureViews
import ModelChecking
import Scheduling
import Verification
import MachineStructure
import swiftfsm
import Timers

public struct Swiftfsm {
    
    let args: SwiftfsmArguments
    let machines: [(fsm: FSMType, dependencies: [Dependency])]
    let gateway: StackGateway
    
    init(args: SwiftfsmArguments, machines: [(FSMType, [Dependency])], gateway: StackGateway) {
        self.args = args
        self.machines = machines
        self.gateway = gateway
    }
    
    func run() {
        let clock = FSMClock(ringletLengths: [:], scheduleLength: 0)
        let machines = self.machines.map { Machine(debug: args.debug, name: $0.fsm.name, fsm: $0.fsm, clock: clock) }
        let clfsmMachineLoader = CLFSMMachineLoader()
        switch self.args.scheduler {
        case .roundRobin:
            let scheduler = RoundRobinSchedulerFactory(gateway: Swiftfsm.gateway, scheduleHandler: clfsmMachineLoader, unloader: clfsmMachineLoader).make()
            let generatorFactory = RoundRobinKripkeStructureGeneratorFactory(gateway: self.gateway)
            self.handleMachines(machines: machines, scheduler: scheduler, generatorFactory: generatorFactory)
        case .passiveRoundRobin:
            let scheduler = PassiveRoundRobinSchedulerFactory(gateway: Swiftfsm.gateway, scheduleHandler: clfsmMachineLoader, unloader: clfsmMachineLoader).make()
            let generatorFactory = PassiveRoundRobinKripkeStructureGeneratorFactory(gateway: self.gateway)
            self.handleMachines(machines: machines, scheduler: scheduler, generatorFactory: generatorFactory)
        case .timeTriggered:
            fatalError("Not Yet Implemented")
        }
    }
    
    private func handleMachines<S: Scheduler, F: KripkeStructureGeneratorFactory>(machines: [Machine], scheduler: S, generatorFactory: F) where F.ViewFactory == AggregateKripkeStructureViewFactory<KripkeState> {
        if !self.args.generateKripkeStructure.isEmpty {
            self.generateKripkeStructure(machines: machines, generatorFactory: generatorFactory, formats: self.args.generateKripkeStructure)
            return
        }
        scheduler.run(machines)
    }
    
    private func generateKripkeStructure<F: KripkeStructureGeneratorFactory>(machines: [Machine], generatorFactory: F, formats: [SwiftfsmArguments.KripkeStructureFormats]) where F.ViewFactory == AggregateKripkeStructureViewFactory<KripkeState> {
        let viewFactories: [AnyKripkeStructureViewFactory<KripkeState>] = formats.map {
            switch $0 {
            case .graphviz:
                return AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory<KripkeState>())
            case .nusmv:
                return AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory<KripkeState>())
            case .tulip:
                fatalError("Tulip view is currently unsupported.")
            case .gexf:
                fatalError("Gexf view is currently unsupported.")
            }
        }
        let generator = generatorFactory.make(fromMachines: machines, usingViewFactory: AggregateKripkeStructureViewFactory(views: viewFactories))
        generator.generate(usingGateway: gateway)
    }
    
    public typealias MachineFactory = (FSMGateway, Timer, FSM_ID) -> (FSMType, [ShallowDependency])
    
    private static let gateway: StackGateway = StackGateway(printer: CommandLinePrinter(
        errorStream: StderrOutputStream(),
        messageStream: StdoutOutputStream(),
        warningStream: StdoutOutputStream()
    ))
    
    public static func makeMachine(name: String, factories: [String: MachineFactory]) -> (FSMType, [Dependency]) {
        let id = Swiftfsm.gateway.id(of: name)
        if let fsm = Swiftfsm.gateway.fsms[id] {
            return (fsm, [])
        }
        guard let factory = factories[name] else {
            fatalError("Unable to load machine named '\(name)' as it is not in the factory list.")
        }
        let (fsm, shallowDependencies) = factory(
            Swiftfsm.gateway,
            FSMClock(ringletLengths: [:], scheduleLength: 0),
            Swiftfsm.gateway.id(of: name)
        )
        Swiftfsm.gateway.fsms[id] = fsm
        let dependencies: [Dependency] = shallowDependencies.map { dependency in
            let (depFSM, deps) = makeMachine(name: name + "_" + dependency.name, factories: factories)
            if dependency.isInvokable, let paramMachine = depFSM.asParameterisedFiniteStateMachine {
                return .invokableParameterisedMachine(paramMachine, deps)
            }
            if dependency.isCallable, let paramMachine = depFSM.asParameterisedFiniteStateMachine {
                return .callableParameterisedMachine(paramMachine, deps)
            }
            if let submachine = depFSM.asControllableFiniteStateMachine {
                return .submachine(submachine, deps)
            }
            fatalError("Unable to create fsm.")
        }
        return (fsm, dependencies)
    }
    
    public static func run(machines: [(FSMType, [Dependency])]) {
        let args: SwiftfsmArguments
        do {
            args = try SwiftfsmArguments.parse()
        } catch let error {
            SwiftfsmArguments.exit(withError: error)
        }
        let swiftfsm = Swiftfsm(args: args, machines: machines, gateway: Swiftfsm.gateway)
        swiftfsm.run()
    }
    
}

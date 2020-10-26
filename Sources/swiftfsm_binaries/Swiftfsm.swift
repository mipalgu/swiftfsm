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
import Scheduling
import Verification
import MachineStructure
import swiftfsm
import Timers

public struct Swiftfsm {

    public typealias MachineFactory = (String, FSMGateway, Timer, FSM_ID) -> (FSMType, [ShallowDependency])
    
    public let gateway: StackGateway = StackGateway(
        printer: CommandLinePrinter(
            errorStream: StderrOutputStream(),
            messageStream: StdoutOutputStream(),
            warningStream: StdoutOutputStream()
        )
    )
    
    public init() {}
    
    public func makeMachines(_ arrangement: FlattenedMetaArrangement) -> [(FSMType, [Dependency])] {
        func _makeMachine<Gateway: VerifiableGateway>(dependency: FlattenedMetaDependency, gateway: Gateway, caller: FSM_ID? = nil) -> (FSMType, [Dependency]) {
            let id = gateway.id(of: dependency.prefixedName)
            let caller = caller ?? id
            guard let fsm = arrangement.fsms[dependency.prefixedName] else {
                fatalError("Unable to load fsm \(dependency.prefixedName)")
            }
            let newGateway = self.createRestrictiveGateway(
                dependency: dependency,
                fsm: fsm,
                gateway: gateway,
                selfID: id,
                caller: caller
            )
            let dependenciesDict: [String: Dependency] = Dictionary(uniqueKeysWithValues: fsm.dependencies.map { dep in
                let id = newGateway.id(of: dep.prefixedName)
                let (depFSM, deps) = _makeMachine(dependency: dep, gateway: gateway, caller: dep.isCallable ? caller : id)
                if dep.isInvocable, let paramMachine = depFSM.asParameterisedFiniteStateMachine {
                    return (dep.name, .invokableParameterisedMachine(paramMachine, deps))
                }
                if dep.isCallable, let paramMachine = depFSM.asParameterisedFiniteStateMachine {
                    return (dep.name, .callableParameterisedMachine(paramMachine, deps))
                }
                if let submachine = depFSM.asControllableFiniteStateMachine {
                    return (dep.name, .submachine(submachine, deps))
                }
                fatalError("Unable to create fsm.")
            })
            let (fsmType, shallowDependencies) = fsm.factory(
                dependency.prefixedName,
                newGateway,
                FSMClock(ringletLengths: [:], scheduleLength: 0),
                caller
            )
            guard let dependencies = shallowDependencies.failMap({
                dependenciesDict[$0.name]
            }) else {
                fatalError("Unable to load dependencies from shallow dependencies")
            }
            gateway.fsms[id] = fsmType
            return (fsmType, dependencies)
        }
        return arrangement.rootFSMs.map {
            _makeMachine(dependency: FlattenedMetaDependency.controllable(prefixedName: $0, name: $0), gateway: self.gateway)
        }
    }
    
    private func createRestrictiveGateway<Gateway: VerifiableGateway>(dependency: FlattenedMetaDependency, fsm: FlattenedMetaFSM, gateway: Gateway, selfID: FSM_ID, caller: FSM_ID?) -> RestrictiveFSMGateway<Gateway, CallbackFormatter> {
        let format: (String) -> String = { name in
            if name == dependency.name {
                return dependency.name
            }
            if let dep = fsm.dependencies.first(where: { $0.name == name }) {
                return dep.name
            }
            return name
        }
        let dependantIds: [FSM_ID] = fsm.dependencies.map { gateway.id(of: $0.prefixedName) }
        let callableIds = fsm.dependencies.filter { $0.isCallable }.map { gateway.id(of: $0.prefixedName) }
        let invocableIds = fsm.dependencies.filter { $0.isInvocable }.map { gateway.id(of: $0.prefixedName) }
        return RestrictiveFSMGateway(
            gateway: gateway,
            selfID: selfID,
            caller: caller ?? selfID,
            callables: Set(callableIds + [selfID]),
            invocables: Set(invocableIds),
            whitelist: Set(dependantIds + [selfID]),
            formatter: CallbackFormatter(format)
        )
    }
    
    public func run(machines: [(FSMType, [Dependency])]) {
        let args: SwiftfsmArguments
        do {
            args = try SwiftfsmArguments.parse()
        } catch let error {
            SwiftfsmArguments.exit(withError: error)
        }
        let swiftfsm = SwiftfsmRunner(args: args, machines: machines, gateway: self.gateway)
        swiftfsm.run()
    }
    
}

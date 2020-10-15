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

    public typealias MachineFactory = (FSMGateway, Timer, FSM_ID) -> (FSMType, [ShallowDependency])
    
    private let gateway: StackGateway = StackGateway(
        printer: CommandLinePrinter(
            errorStream: StderrOutputStream(),
            messageStream: StdoutOutputStream(),
            warningStream: StdoutOutputStream()
        )
    )
    
    public init() {}
    
    public func makeMachine(name: String, dependantMachines: [String: [String]], callableMachines: [String: [String]], invocableMachines: [String: [String]], factories: [String: MachineFactory], caller: FSM_ID? = nil) -> (FSMType, [Dependency]) {
        func _makeMachine<Gateway: VerifiableGateway>(name: String, prefix: String?, gateway: Gateway, caller: FSM_ID? = nil) -> (FSMType, [Dependency]) {
            let prefixedName = (prefix.map { $0 + "." } ?? "") + name
            let id = gateway.id(of: prefixedName)
            guard let factory = factories[prefixedName] else {
                fatalError("Unable to load machine named '\(prefixedName)' as it is not in the factory list.")
            }
            let caller = caller ?? id
            guard
                let dependantMachines = dependantMachines[prefixedName],
                let callableMachines = callableMachines[prefixedName],
                let invocableMachines = invocableMachines[prefixedName]
            else {
                fatalError("Unable to load dependency lists for machine '\(prefixedName)'")
            }
            let newGateway = self.createRestrictiveGateway(
                forMachine: name,
                gateway: gateway,
                dependantMachines: dependantMachines,
                callableMachines: callableMachines,
                invocableMachines: invocableMachines,
                prefix: prefix,
                selfID: id,
                caller: caller
            )
            let dependenciesDict: [String: Dependency] = Dictionary(uniqueKeysWithValues: dependantMachines.map { dep in
                let id = newGateway.id(of: dep)
                let (depFSM, deps) = _makeMachine(name: dep, prefix: prefixedName, gateway: gateway, caller: callableMachines.contains(dep) ? caller : id)
                if invocableMachines.contains(dep), let paramMachine = depFSM.asParameterisedFiniteStateMachine {
                    return (dep, .invokableParameterisedMachine(paramMachine, deps))
                }
                if callableMachines.contains(dep), let paramMachine = depFSM.asParameterisedFiniteStateMachine {
                    return (dep, .callableParameterisedMachine(paramMachine, deps))
                }
                if let submachine = depFSM.asControllableFiniteStateMachine {
                    return (dep, .submachine(submachine, deps))
                }
                fatalError("Unable to create fsm.")
            })
            let (fsm, shallowDependencies) = factory(
                newGateway,
                FSMClock(ringletLengths: [:], scheduleLength: 0),
                caller
            )
            guard let dependencies = shallowDependencies.failMap({
                dependenciesDict[$0.name]
            }) else {
                fatalError("Unable to load dependencies from shallow dependencies")
            }
            self.gateway.fsms[id] = fsm
            return (fsm, dependencies)
        }
        return _makeMachine(name: name, prefix: nil, gateway: self.gateway)
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
    
    fileprivate func createRestrictiveGateway<Gateway: VerifiableGateway>(forMachine machine: String, gateway: Gateway, dependantMachines: [String], callableMachines: [String], invocableMachines: [String], prefix: String?, selfID: FSM_ID, caller: FSM_ID?) -> RestrictiveFSMGateway<Gateway, CallbackFormatter> {
        let format: (String) -> String = {
            if $0 == machine {
                return (prefix.map { $0 + "." } ?? "") + machine
            }
            return (prefix.map { $0 + "." } ?? "") + machine + "." + $0
        }
        let dependantIds: [FSM_ID] = dependantMachines.map { gateway.id(of: format($0)) }
        let callableIds = callableMachines.map { gateway.id(of: format($0)) }
        let invocableIds = invocableMachines.map { gateway.id(of: format($0)) }
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
    
}

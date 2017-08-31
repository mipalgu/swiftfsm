/*
 * CLFSMMachineLoader.swift
 * swiftfsm
 *
 * Created by Callum McColl on 16/12/2015.
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
import IO //needed for printer
import swiftfsm_helpers 
import swift_CLReflect


/**
 *  Is responsible for loading CLFSM machines.
 */
public class CLFSMMachineLoader: MachineLoader {

    public func load(path: String) -> [AnyScheduleableFiniteStateMachine] {
        
        let cPath = path.utf8CString 

        print("CLFSMMachineLoader() - path: \(path)") //DEBUG

        let printer: CommandLinePrinter = 
            CommandLinePrinter(
                errorStream: StderrOutputStream(),
                messageStream: StdoutOutputStream()
            )
        
        let dynamicLibraryCreator = DynamicLibraryCreator(printer: printer)

        guard let dlrCFSM = dynamicLibraryCreator.open(path: "/usr/local/lib/libCFSMs.so") else {
            fatalError("Error creating DLC for CFSMs")
        }

        let loadMachineTuple = dlrCFSM.getSymbolPointer(symbol: "_C_loadAndAddMachine")
        guard let loadMachinePtr = loadMachineTuple.0 else {
            fatalError(loadMachineTuple.1 ?? "getSymbolPointer(loadAndAddMachine): unknown error")
        }

        let destroyCFSMTuple = dlrCFSM.getSymbolPointer(symbol: "_C_destroyCFSM")
        guard let destroyCFSMPtr = destroyCFSMTuple.0 else {
            fatalError(destroyCFSMTuple.1 ?? "getSymbolPointer(destroyCFSM): unknown error")
        }

        print("CLFSMMachineLoader() - loadMachinePtr: \(loadMachinePtr)") //DEBUG

        let machineID = cPath.withUnsafeBufferPointer { loadMachine(loadMachinePtr, $0.baseAddress, false) }
        if (machineID == -1) {
            fatalError("cfsm_load() - Failed to load machine")
        }

        print("CLFSMMachineLoader() - machineID: \(machineID)") //DEBUG

        //test the meta machine
        //let metaMachine = refl_getMetaMachine(UInt32(machineID), nil)
        //refl_invokeOnEntry(metaMachine, 0, nil)
        
        let dlCloseResult = dlrCFSM.close()
        if (!dlCloseResult.0) { print(dlCloseResult.1 ?? "No error message for DynamicLibraryResource.close()!") }
        
        //destroyCFSM(destroyCFSMPtr)
        //return [AnyScheduleableFiniteStateMachine]()
        return createFiniteStateMachines([Int(machineID)]) 
    }
    
    /**
     * Creates an array of AnyScheduleableFiniteStateMachine from an array of CLFSM machine IDs
     * 
     * - Parameter machineIDs the array of CLFSM machine IDs
     * - Return an array of AnyScheduleableFiniteStateMachines
     */
    public func createFiniteStateMachines(_ machineIDs: [Int]) -> [AnyScheduleableFiniteStateMachine] {
        var finiteStateMachines = [AnyScheduleableFiniteStateMachine]()
        print("create fsm: looping through machine IDs") //DEBUG
        for machineID in machineIDs {
            print("creating fsm for \(machineID)") //DEBUG
            guard let metaMachine = refl_getMetaMachine(UInt32(machineID), nil) else {
                fatalError("Could not get metamachine for machineID = \(machineID)")
            }
            print("getting name for \(machineID)") //DEBUG
            let name = String(cString: refl_getMetaMachineName(metaMachine, nil))
            print("creating states for \(machineID)") //DEBUG
            let states = createStates(metaMachine)
            let finiteStateMachine = FSM(name, initialState: states[0])
            finiteStateMachines.append(finiteStateMachine)
        }
        return finiteStateMachines
    }

    /**
     * Creates an array of CFSMState from the metastates of the underlying CLReflect metamachine
     * 
     * - Parameter metaMachine the CLReflect metamachine
     * - Return an array of CFSMStates 
     */
    public func createStates(_ metaMachine: refl_metaMachine) -> [CFSMState] {
        var cfsmStates = [CFSMState]()
        print("getting metastates for metamachine") //DEBUG
        guard let metaStates = refl_getMetaStates(metaMachine, nil) else {
            fatalError("Could not get meta states for metamachine")
        }
        print("getting number of states for metamachine") //DEBUG
        let numberOfStates = refl_getNumberOfStates(metaMachine, nil)
        print("looping through metastates") //DEBUG
        for stateNumber in 0...numberOfStates - 1 {
            guard let metaState = metaStates[Int(stateNumber)] else {
                fatalError("Could not get meta state for state number = \(stateNumber)")
            }
            print("getting name for metastate \(stateNumber)") //DEBUG
            let stateName = String(cString: refl_getMetaStateName(metaState, nil))
            print("constructing cfsm state for \(stateName)") //DEBUG
            let cfsmState = CFSMState(stateName, metaMachine: metaMachine, stateNumber: Int(stateNumber))
            cfsmStates.append(cfsmState)
        }
        print("adding transitions to cfsm states") //DEBUG
        addTransitions(cfsmStates, metaMachine: metaMachine)
        return cfsmStates
    }
    
    /**
     * Adds transitions between CFSM states according to the CLReflect metamachine's metatransitions
     * 
     * Parameter cfsmStates the array of CFSMStates to create transitions for
     * Parameter metaMachine the underlying CLReflect metamachine
     */
    public func addTransitions(_ cfsmStates: [CFSMState], metaMachine: refl_metaMachine) {
        print("getting metastates (addTransitions)") //DEBUG
        guard let metaStates = refl_getMetaStates(metaMachine, nil) else {
                fatalError("Could not get metastates for metamachine")
        }
        for var (_, cfsmState) in cfsmStates.enumerated()
        {
            print("getting source metastate")
            let sourceMetaState = metaStates[cfsmState.stateNumber]
            print("getting metatransitions for state \(cfsmState.stateNumber)") //DEBUG
            guard let metaTransitions = refl_getMetaTransitions(sourceMetaState, nil) else {
                fatalError("Could not get metatransitions for state: \(cfsmState.name)") //DEBUG
            }
            print("getting number of metatransitions for \(cfsmState.stateNumber)") //DEBUG
            let numberOfTransitions = refl_getNumberOfTransitions(sourceMetaState, nil)
            for transitionNumber in 0...numberOfTransitions - 1 {
                print("getting mettransition for trans num \(transitionNumber)") //DEBUG
                let metaTransition = metaTransitions[Int(transitionNumber)]
                print("getting target state for trans \(transitionNumber)") //DEBUG
                let targetStateNumber = refl_getMetaTransitionTarget(metaTransition, nil)
                print("getting target cfsm state") //DEBUG

                guard let targetCFSMState = cfsmStates.first(where: { $0.stateNumber == Int(targetStateNumber) }) else {
                    fatalError("Could not get target state for transition \(transitionNumber)")
                }

                print("adding transition") //DEBUG
                cfsmState.addTransition(Transition(targetCFSMState) {
                    let state = $0 as! CFSMState
                    return state.evaluateTransition(transitionNumber: Int(transitionNumber)) 
                })
            }
        }
    }

}

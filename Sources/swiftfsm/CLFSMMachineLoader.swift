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


/**
 *  Is responsible for loading CLFSM machines.
 */
public class CLFSMMachineLoader: MachineLoader {

    public func load(path: String) -> [AnyScheduleableFiniteStateMachine] {
       
        let debug = true; //gross but no preprocessor

        //perhaps add printer to constructor so we can use the one in main.swift
        let printer: CommandLinePrinter = 
            CommandLinePrinter(
                errorStream: StderrOutputStream(),
                messageStream: StdoutOutputStream()
            )
        
        let dynamicLibraryCreator = DynamicLibraryCreator(printer: printer)
       
        /*
        //access libCFMs via dlopen/dlsym and set fsm vector and fsm count
        guard let dlrCFSM = dynamicLibraryCreator.open(path: "/usr/local/lib/libCFSMs.so") else {
            fatalError("Error creating DLC for CFSMs")
        }

        let setNumMachinesTuple = dlrCFSM.getSymbolPointer(symbol: "set_number_of_machines")
        guard let setNumMachinesPtr = setNumMachinesTuple.0 else {
            fatalError(setNumMachinesTuple.1 ?? "getSymbolPointer(set_number_of_machines): unknown error")
        }

        if (debug) { print("set num machines ptr: \(setNumMachinesPtr)") }

        //Set number_of_machines in cfsm (required by CLMacros)
        //NYI: get count from command line args
        
        //Place machines in vector and set in cfsm (required by CLMacros)
        //NYI: set fsm vector
        */

        //get pointer to CLFSM machine library
        guard let dynamicLibraryResource = dynamicLibraryCreator.open(path: path) else {
            fatalError("Error creating DynamicLibraryResource")
        }
        
        //get pointer to machine create function
        let createMachineTuple = dynamicLibraryResource.getSymbolPointer(symbol: "CLM_Create_PingPongCLFSM")
        guard let createMachinePointer = createMachineTuple.0 else {
            fatalError(createMachineTuple.1 ?? "getSymbolPointer(): unknown error")
        }

        if (debug) { print("machine create func pointer: \(createMachinePointer)") }
        
        
        //call machine create function and get pointer to machine
        guard let machinePointer = createMachine(createMachinePointer) else {
            fatalError("Error getting CL machine pointer")
        }

        if (debug) { print("machine pointer: \(machinePointer)") }
        

        //get pointer to create scheduled meta machine function
        let createScheduledMetaMachineTuple = dynamicLibraryResource.getSymbolPointer(symbol: "Create_ScheduledMetaMachine")
        guard let createScheduledMetaMachinePointer = createScheduledMetaMachineTuple.0 else {
            fatalError(createScheduledMetaMachineTuple.1 ?? "getSymbolPointer(): unknown error")
        }

        if (debug) { print("create scheduled meta machine func pointer: \(createScheduledMetaMachinePointer)") }
        

        
        //call create scheduled meta machine and get pointer to meta machine
        guard let scheduledMetaMachinePointer = createMetaMachine(createScheduledMetaMachinePointer, machinePointer) else {
            fatalError("error creating meta machine")
        }
    
        if (debug) { print("scheduled meta machine pointer: \(scheduledMetaMachinePointer)") }
               
        //loadMachine(createMachinePointer, createScheduledMetaMachinePointer, 0)

        //TODO: how to work with C enums (imported as structs)
        //TODO: should make swift wrappers for these API calls
        
        //initCLReflectAPI()
        //registerMetaMachine(scheduledMetaMachinePointer, 0)
        invokeOnEntry(scheduledMetaMachinePointer, 0)


        /*
        //convert unsafemutablerawpointer
        let opaquePtr = OpaquePointer(scheduledMetaMachinePointer)
        let metaMachinePtr = UnsafeMutablePointer<refl_metaMachine>(opaquePtr)
        let metaMachine = metaMachinePtr.pointee

        refl_invokeOnEntry(metaMachine, 0, nil) <-- segfault
        */ 

        //let mm = refl_getMetaMachine(0, nil)
        //refl_invokeOnEntry(mm, 0, nil)

        let dlCloseResult = dynamicLibraryResource.close()
        if (!dlCloseResult.0) { print(dlCloseResult.1 ?? "No error message for DynamicLibraryResource.close()!") }

        return []
    }

}

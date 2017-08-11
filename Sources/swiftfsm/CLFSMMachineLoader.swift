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
import swiftfsm_helpers //testMachineFactory


/**
 *  Is responsible for loading CLFSM machines.
 */
public class CLFSMMachineLoader: MachineLoader {

    public func load(path: String) -> [AnyScheduleableFiniteStateMachine] {
       
        //perhaps add printer to constructor so we can use the one in main.swift
        let printer: CommandLinePrinter = 
            CommandLinePrinter(
                errorStream: StderrOutputStream(),
                messageStream: StdoutOutputStream()
            )
        
        //get pointer to machine .so
        let dynamicLibraryCreator = DynamicLibraryCreator(printer: printer)
        guard let dynamicLibraryResource = dynamicLibraryCreator.open(path: path) else {
            fatalError("Error creating DynamicLibraryResource")
        }
        
        //get pointer to machine create function
        let createMachineTuple = dynamicLibraryResource.getSymbolPointer(symbol: "CLM_Create_PingPongCLFSM")
        guard let createMachinePointer = createMachineTuple.0 else {
            fatalError(createMachineTuple.1 ?? "getSymbolPointer(): unknown error")
        }

        //call machine create function and get pointer to machine
        guard let machinePointer = testMachineFactory(createMachinePointer) else {
            fatalError("Error getting CL machine pointer")
        }

        print("machine pointer: \(machinePointer)")

        //get pointer to create meta machine function
        let createMetaMachineTuple = dynamicLibraryResource.getSymbolPointer(symbol: "Create_MetaMachine")
        guard let createMetaMachinePointer = createMetaMachineTuple.0 else {
            fatalError(createMetaMachineTuple.1 ?? "getSymbolPointer(): unknown error")
        }

        print("create meta machine func pointer: \(createMetaMachinePointer)")

        //get pointer to create scheduled meta machine function
        let createScheduledMetaMachineTuple = dynamicLibraryResource.getSymbolPointer(symbol: "Create_ScheduledMetaMachine")
        guard let createScheduledMetaMachinePointer = createScheduledMetaMachineTuple.0 else {
            fatalError(createScheduledMetaMachineTuple.1 ?? "getSymbolPointer(): unknown error")
        }

        print("create scheduled meta machine func pointer: \(createScheduledMetaMachinePointer)")

        //test running Ping_OnEntry(refl_machine_t machine, refl_userData_t data) 
        //get pointer to Ping_OnEntry function
        let pingOnEntryTuple = dynamicLibraryResource.getSymbolPointer(symbol: "refl_invokeOnEntry")
        guard let pingOnEntryPointer = pingOnEntryTuple.0 else {
            fatalError(pingOnEntryTuple.1 ?? "getSymbolPointer(): unknown error")
        }

        print("ping on entry func pointer: \(pingOnEntryPointer)")

        return []
    }

}

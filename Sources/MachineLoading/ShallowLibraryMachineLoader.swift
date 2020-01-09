/*
 * ShallowLibraryMachineLoader.swift
 * MachineLoading
 *
 * Created by Callum McColl on 9/1/20.
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

import FSM
import Gateways
import Functional
import IO
import swiftfsm_helpers
import Libraries
import swiftfsm

final class ShallowLibraryMachineLoader {
    
    //swiftlint:disable:next line_length
    fileprivate typealias SymbolSignature = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void

    /*
     *  This is used to remember factories for paths, therefore allowing us to
     *  just use this instead of loading it from the file system.
     */
    fileprivate static var cache: [String: SymbolSignature] = [:]

    internal let loader: LibrarySymbolLoader

    /**
     *  Used to print error messages.
     */
    internal let printer: Printer

    /**
     *  Create a new `LibraryMachineLoader`.
     *
     *  - Parameter loader: Used to load the symbols.
     *
     *  - Parameter printer: Error messages get sent here.
     */
    internal init(loader: LibrarySymbolLoader, printer: Printer) {
        self.loader = loader
        self.printer = printer
    }

    /**
     *  Remove all the factories from the cache.
     */
    internal func clearCache() {
        type(of: self).cache = [:]
    }

    /**
     *  Load the machines from the library specified from the path.
     *
     *  To accomplish this the machines factory function is executed which
     *  returns the necessary machine data.
     *
     *  - Parameter path: The path to the library.
     *
     *  - Returns: A tuple containing the FSM and all of its dependencies.
     */
    internal func load<Gateway: FSMGateway>(
        name: String,
        gateway: Gateway,
        clock: Timer,
        path: String
    ) -> (FSMType, [ShallowDependency])? {
        // Ignore empty paths
        guard false == path.isEmpty else {
            return nil
        }
        let id = gateway.id(of: name)
        // Load the factory from the cache if it is there.
        if let factory = type(of: self).cache[path] {
            return self.call(factory: factory, gateway: gateway, clock: clock, id: id)
        }
        // Load the factory from the dynamic library.
        guard let data = self.loadMachine(name: name, gateway: gateway, clock: clock, path: path) else {
            return nil
        }
        return data
    }

    fileprivate func loadMachine<Gateway: FSMGateway>(
        name: String,
        gateway: Gateway,
        clock: Timer,
        path: String
    ) -> (FSMType, [ShallowDependency])? {
        // Get main method symbol
        guard let symbolName = self.fetchSymbolName(fromPath: path) else {
            self.printer.error(str: "Unable to synthesize the factory function symbol name from path '\(path)'")
            return nil
        }
        let id = gateway.id(of: name)
        do {
            return try self.loader.load(symbol: symbolName, inLibrary: path) { (factory: SymbolSignature) -> (FSMType, [ShallowDependency])? in
                return self.call(factory: factory, gateway: gateway, clock: clock, id: id)
            }
        } catch let error as LibrarySymbolLoader.Errors {
            switch error {
            case .error(let message):
                self.printer.error(str: message)
            }
            return nil
        } catch {
            self.printer.error(str: "Unable to load machine \(name)")
            return nil
        }
    }

    fileprivate func fetchSymbolName(fromPath path: String) -> String? {
        let components = path.split(separator: "/")
        guard var file = components.last else {
            return nil
        }
        if file.hasPrefix("lib") {
            file.removeFirst(3)
        }
        let split = file.split(separator: ".")
        guard let first = split.first else {
            return nil
        }
        let filename = ([first] + Array(split.dropFirst().dropLast())).reduce("", +)
        let name = filename.hasSuffix("Machine") ? String(filename.dropLast(7)) : filename
        if true == name.isEmpty {
            return nil
        }
        print("Loading symbol: make_\(name)")
        return "make_" + name
    }

    fileprivate func call(factory: SymbolSignature, gateway: FSMGateway, clock: Timer, id: FSM_ID) -> (FSMType, [ShallowDependency])? {
        var gateway = gateway
        var clock = clock
        var id = id
        return withUnsafeMutablePointer(to: &gateway) {
            let gatewayPointer = UnsafeMutableRawPointer($0)
            return withUnsafeMutablePointer(to: &clock) {
                let clockPointer = UnsafeMutableRawPointer($0)
                return withUnsafeMutablePointer(to: &id) {
                    let idPointer = UnsafeMutableRawPointer($0)
                    var fsm: FSMType?
                    var dependencies: [ShallowDependency]?
                    var callback: (FSMType, [ShallowDependency]) -> Void = { fsm = $0; dependencies = $1 }
                    return withUnsafeMutablePointer(to: &callback) {
                        let callbackPointer = UnsafeMutableRawPointer($0)
                        factory(gatewayPointer, clockPointer, idPointer, callbackPointer)
                        guard let fsm = fsm, let dependencies = dependencies else {
                            self.printer.error(str: "The factory function does not call the callback function.")
                            return nil
                        }
                        return (fsm, dependencies)
                    }
                }
            }
        }
    }
    
}
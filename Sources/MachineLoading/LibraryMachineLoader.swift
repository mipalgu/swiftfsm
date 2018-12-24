/*
 * LibraryMachineLoader.swift
 * swiftfsm
 *
 * Created by Callum McColl on 26/08/2015.
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
import Functional
import IO
import swiftfsm_helpers
import Libraries
import swiftfsm
import Trees

/**
 *  Load a `Machine` from a library.
 *
 *  This class conforms to `MachineLoader`.
 */
public class LibraryMachineLoader: MachineLoader {
    
    fileprivate typealias SymbolSignature = @convention(c) (Any, Any, Any) -> Any
    
    /*
     *  This is used to remember factories for paths, therefore allowing us to
     *  just use this instead of loading it from the file system.
     */
    private static var cache: [String: SymbolSignature] = [:]

    /**
     *  Used to create the libraries.
     *
     *  - Note: It would be a good idea for the LibraryCreator to leverage the
     *      strategy pattern as it would then be able to decide which library
     *      creator to use from the path.  This is not yet implemented, but
     *      would allow multiple types of paths to be used instead of just file
     *      paths.  For instance it could allow the loading of a library from a
     *      url or a network stream.
     */
    public let creator: LibraryCreator

    /**
     *  Used to print error messages.
     */
    public let printer: Printer
    
    /**
     *  Create a new `LibraryMachineLoader`.
     *
     *  - Parameter creator: Used to create the `LibraryResource`s.
     *
     *  - Parameter printer: Error messages get sent here.
     */
    public init(creator: LibraryCreator, printer: Printer) {
        self.creator = creator
        self.printer = printer
    }

    /**
     *  Remove all the factories from the cache.
     */
    public func clearCache() {
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
    public func load(name: String, fsms: Node<String>?, invoker: Invoker, clock: Timer, path: String) -> (FSMType, [Dependency])? {
        // Ignore empty paths
        guard
            false == path.isEmpty,
            let fsms = fsms ?? self.fetchFSMName(fromLibraryPath: path).map({ Node($0) })
        else {
            return nil
        }
        // Load the factory from the cache if it is there.
        if let factory = type(of: self).cache[path] {
            return factory(name, invoker, clock) as? (FSMType, [Dependency])
        }
        // Load the factory from the dynamic library.
        guard
            let resource = self.creator.open(path: path),
            let data = self.loadMachine(name: name, fsms: fsms, invoker: invoker, clock: clock, library: resource)
        else {
            return nil
        }
        return data
    }

    private func loadMachine(
        name: String,
        fsms: Node<String>,
        invoker: Invoker,
        clock: Timer,
        library: LibraryResource
    ) -> (FSMType, [Dependency])? {
        // Get main method symbol
        let symbolName = "make_" + fsms.content
        let result: (symbol: UnsafeMutableRawPointer?, error: String?) =
            library.getSymbolPointer(symbol: symbolName)
        // Error with fetching symbol
        guard let symbol = result.symbol else {
            self.printer.error(str: result.error ?? "Unable to fetch symbol '\(symbolName)' for machine \(name)")
            return nil
        }
        // Convert the sybmol to a factory function.
        let factory = unsafeBitCast(symbol, to: SymbolSignature.self)
        // Add the factory to the cache, call it and return the result.
        type(of: self).cache[library.path] = factory
        guard let data = factory(name, invoker, clock) as? (FSMType, [Dependency]) else {
            self.printer.error(str: "Unable to call factory function '\(symbolName)' for machine \(name)")
            return nil
        }
        return data
    }
    
    fileprivate func fetchFSMName(fromLibraryPath path: String) -> String? {
        guard
            let lastComponent = path.split(separator: "/").last,
            let name = lastComponent.split(separator: ".").first?.trimmingCharacters(in: .whitespaces),
            false == name.isEmpty
            else {
                return nil
        }
        return true == name.hasPrefix("lib") ? String(name.dropFirst(3)) : String(name)
    }
    
}

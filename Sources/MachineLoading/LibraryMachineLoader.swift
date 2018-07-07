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

/**
 *  Load a `Machine` from a library.
 *
 *  This class conforms to `MachineLoader`.
 */
public class LibraryMachineLoader: MachineLoader {
    
    /*
     *  This is used to remember factories for paths, therefore allowing us to
     *  just use this instead of loading it from the file system.
     */
    private static var cache: [String: FSMArrayFactory] = [:]

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
     *  To accomplish this the main method is called on the library.  Therefore
     *  the library is responsible for adding itself to the factories array in
     *  `FSM.Factories`.
     *
     *  - Parameter path: The path to the library.
     *
     *  - Returns: An array of `AnyScheduleableFiniteStateMachine`s.  If there
     *  was a problem, then the array is empty.
     */
    public func load(path: String) -> AnyScheduleableFiniteStateMachine? {
        // Ignore empty paths
        if (path.characters.count < 1) {
            return nil
        }
        // Load the factory from the cache if it is there.
        if let factory = type(of: self).cache[path] {
            return factory()
        }
        // Load the factory from the dynamic library.
        if let fsms = self.creator.open(path: path) >>- self.loadMachine {
            return fsms
        }
        return nil
    }

    private func loadMachine(
        library: LibraryResource
    ) -> AnyScheduleableFiniteStateMachine? {
        // Get main method symbol
        let result: (symbol: UnsafeMutableRawPointer?, error: String?) =
            library.getSymbolPointer(symbol: "main")
        // Error with fetching symbol
        if (result.error != nil) {
            self.printer.error(str: result.error!)
            return nil
        }
        // How many factories do we have now?
        let count: Int = getFactoryCount() 
        // Call the method
        invoke_func(result.symbol!)
        // Did the factory get added?
        if (getFactoryCount() == count) {
            self.printer.error(str: "Library was loaded but factory was not added")
            return nil
        }
        // Get the factory, add it to the cache, call it and return the result.
        let factory: FSMArrayFactory = getLastFactory()!
        type(of: self).cache[library.path] = factory
        return factory()
    }
    
}

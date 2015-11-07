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

/**
 *  Load a machine from a library.
 *
 *  This class conforms to MachineLoader.
 */
public class LibraryMachineLoader: MachineLoader {
    
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
    
    public init(creator: LibraryCreator) {
        self.creator = creator
    }
    
    /**
     *  Load the machines from the library specified from the path.
     *
     *  In order to load the machines the main method is called on all of the 
     *  loaded libraries.  The individual libraries are responsible for loading
     *  themselves into the scheduler.
     *
     *  - Note: This should change as it would be better to call a method which
     *      returns an array of machines to load and do the actual loading into
     *      the scheduler within this method.  This would ensure that the
     *      libraries would not need to know how to add machines to the
     *      scheduler.
     */
    public func load(path: String) -> FiniteStateMachine? {
        // Ignore empty paths
        if (path.characters.count < 1) {
            return nil
        }
        // Create the library resource.
        let lib: LibraryResource? = self.creator.open(path)
        if lib == nil {
            return nil
        }
        // Load the machines
        return self.loadMachine(lib!)
    }
    
    private func loadMachine(library: LibraryResource) -> FiniteStateMachine? {
        // Get main method symbol
        let result: (symbol: UnsafeMutablePointer<Void>, error: String?) =
            library.getSymbolPointer("main")
        // Error with fetching symbol
        if (result.error != nil) {
            print(result.error!)
            return nil
        }
        // Call the method
        invoke_fun(result.symbol)
        // Get the factory that was added
        let f: Factories.FiniteStateMachineFactory? = getLastFactory()
        if (f == nil) {
            return nil
        }
        // Call the factory
        return f!()
    }
    
}
/*
 * LibrarySymbolLoader.swift
 * Libraries
 *
 * Created by Callum McColl on 6/1/19.
 * Copyright © 2019 Callum McColl. All rights reserved.
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

public final class LibrarySymbolLoader {

    public enum Errors: Error {

        public var message: String {
            switch self {
            case .error(let message):
                return message
            }
        }

        case error(message: String)
    }

    /*
     *  Used to create the libraries.
     *
     *  - Note: It would be a good idea for the LibraryCreator to leverage the
     *      strategy pattern as it would then be able to decide which library
     *      creator to use from the path.  This is not yet implemented, but
     *      would allow multiple types of paths to be used instead of just file
     *      paths.  For instance it could allow the loading of a library from a
     *      url or a network stream.
     */
    fileprivate let creator: LibraryCreator

    /**
     *  Create a new `LibrarySymbolLoader`.
     *
     *  - Parameter creator: Used to create the `LibraryResource`s.
     */
    public init(creator: LibraryCreator) {
        self.creator = creator
    }

    public func load<T, U>(symbol symbolName: String, inLibrary path: String, _ callback: (T) throws -> U) throws -> U {
        // Load the factory from the dynamic library.
        guard let resource = self.creator.open(path: path) else {
            throw Errors.error(message: "Unable to create a resource for libray at path '\(path)'")
        }
        let result: (symbol: UnsafeMutableRawPointer?, error: String?) = resource.getSymbolPointer(symbol: symbolName)
        // Error with fetching symbol
        guard let symbol = result.symbol else {
            throw Errors.error(
                message: result.error ?? "Unable to fetch symbol '\(symbolName)' in library at path '\(path)'"
            )
        }
        // Convert the symbol to the specified type.
        let type = unsafeBitCast(symbol, to: T.self)
        return try callback(type)
    }

}

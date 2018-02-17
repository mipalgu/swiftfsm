/*
 * DynamicLibraryResource.swift
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

 #if os(OSX)
 import Darwin
 #elseif os(Linux)
 import Glibc
 #endif

/**
 *  A library resource for a dynamic library.
 *
 *  This class is used to interact with dynamic libraries.  This class should
 *  not be created directly.  Instead you should use the `DynamicLibraryCreator`
 *  class to create this resource.
 */
public class DynamicLibraryResource: LibraryResource {
    
    /**
     *  A void pointer to the dynamic library that was loaded using dlopen.
     */
    private let handler: UnsafeMutableRawPointer
    
    /**
     *  The path on the file system to the dynamic library.
     */
    public let path: String
    
    /**
     *  Create the resource.
     *
     *  Do not create this resource directly.  Instead use
     *  `DynamicLibraryCreator`.
     *
     *  - Parameter handler: A raw pointer to the dynamic library.
     *
     *  - Parameter path: The path to where the dynamic library is located.
     */
    public init(handler: UnsafeMutableRawPointer, path: String) {
        self.handler = handler
        self.path = path
    }
    
    /**
     *  Return a void pointer to a symbol within the dynamic library.
     *
     *  If this method works successfully then error will be set to nil and the
     *  void pointer will be returned.
     *
     *  If this method is unable to find the symbol or there is an error when
     *  attempting to retrieve the symbol then the symbol variable within the
     *  tuple will be a null pointer and the error variable will be set with an
     *  error message.
     *
     *  - Parameter symbol: The symbol as a string.
     *
     *  - Returns: A tuple where the first element is a raw pointer to the
     *  symbol and the second element is an error message.
     */
    public func getSymbolPointer(symbol: String) -> (
        symbol: UnsafeMutableRawPointer?,
        error: String?
    ) {
        // Attempt to get the symbol
        let sym: UnsafeMutableRawPointer? = dlsym(self.handler, symbol)
        if (sym != nil) {
            // Successful retrieval of symbol
            return (sym, error: nil)
        }
        // Unable to retrieve symbol - retrieve the error
        return (symbol: sym, error: String(cString: dlerror()))
    }
    
    /**
     *  Attemp to close the dynamic library resource.
     *
     *  dlopen and dlclose leverage reference counting which means that every
     *  time you call dlopen or use DynamicLibraryCreator.open then you must
     *  call this close method.
     *
     *  If there is an error with closing the resource then the successful
     *  property will be set to false and the error property set to an error
     *  message String.  If the close was successful then the successful
     *  property will be set to true and the error property set to nil.
     */
    public func close() -> (successful: Bool, error: String?) {
        // Attempt to close the library.
        let result: CInt = dlclose(self.handler)
        if (result == 0) {
            // Succesfully closed library.
            return (successful: true, error: nil)
        }
        // Error
        return (successful: false, error: String(cString: dlerror()))
    }
    
}

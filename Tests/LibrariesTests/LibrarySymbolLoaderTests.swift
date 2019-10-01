/*
 * LibrarySymbolLoaderTests.swift 
 * LibrariesTests 
 *
 * Created by Callum McColl on 27/09/2019.
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

@testable import Libraries
@testable import loader_tests

import XCTest

public class LibrarySymbolLoaderTests: LibrariesTestCase {

    public static var allTests: [(String, (LibrarySymbolLoaderTests) -> () throws -> Void)] {
        return [
            ("test_canLoadVoidFunction", test_canLoadVoidFunction)
        ]
    }
    
    fileprivate var resource: DynamicLibraryResource!
    
    public override func setUp() {
        super.setUp()
        #if os(macOS)
        let ext = "dylib"
        #else
        let ext = "so"
        #endif
        let path = self.root + "/loader_tests/.build/debug/libloader_tests.\(ext)"
        guard let handler = dlopen(path, RTLD_NOW | RTLD_LOCAL) else {
            XCTFail(String(cString: dlerror()))
            return
        }
        self.resource = DynamicLibraryResource(handler: handler, path: path)
    }
    
    public override func tearDown() {
        _ = self.resource?.close()
        super.tearDown()
    }
    
    fileprivate func rebind<T, U>(symbol: String, to type: T.Type, _ callback: (T) -> U) -> U? {
        let (fetchedSymbol, error) = self.resource.getSymbolPointer(symbol: "test")
        if let error = error {
            XCTFail(error)
            return nil
        }
        guard let symbol = fetchedSymbol else {
            XCTFail("Unable to fetch valid symbol.")
            return nil
        }
        let f = unsafeBitCast(symbol, to: type)
        return callback(f)
    }

    public func test_canLoadVoidFunction() {
        _ = self.rebind(symbol: "test", to: (@convention(c) () -> Void).self) { $0() }
    }
    
    public func test_canLoadIntFunction() {
        guard let result = self.rebind(symbol: "test2", to: (@convention(c) (Any) -> Any).self, { $0(2) as? Int }) else {
            return
        }
        XCTAssertEqual(result, .some(4))
    }
    
    public func test_canLoadPersonFunction() {
        let bob = Person(name: "Bob")
        guard let result = self.rebind(symbol: "test3", to: (@convention(c) (Any) -> Any).self, { $0(bob) as? Person }) else {
            return
        }
        XCTAssertEqual(result, .some(Person(name: "Bill")))
    }

}

/*
 * KripkeStatePropertyListConverterTests.swift 
 * VerificationTests 
 *
 * Created by Callum McColl on 17/02/2018.
 * Copyright © 2018 Callum McColl. All rights reserved.
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

@testable import Verification
import XCTest

import KripkeStructure

public final class KripkeStatePropertyListConverterTests: VerificationTestCase {

    fileprivate var converter: KripkeStatePropertyListConverter!

    public override func setUp() {
        self.converter = KripkeStatePropertyListConverter()
    }

    //swiftlint:disable:next function_body_length
    public func test_convertsSuccessfully() {
        let list: KripkeStatePropertyList = [
            "b": KripkeStateProperty(
                type: .Bool,
                value: true
            ),
            "i": KripkeStateProperty(
                type: .Int,
                value: Int(1)
            ),
            "i8": KripkeStateProperty(
                type: .Int8,
                value: Int8(1)
            ),
            "i16": KripkeStateProperty(
                type: .Int16,
                value: Int16(1)
            ),
            "i32": KripkeStateProperty(
                type: .Int32,
                value: Int32(1)
            ),
            "i64": KripkeStateProperty(
                type: .Int64,
                value: Int64(1)
            ),
            "ui": KripkeStateProperty(
                type: .UInt,
                value: UInt(1)
            ),
            "ui8": KripkeStateProperty(
                type: .UInt8,
                value: UInt8(1)
            ),
            "ui16": KripkeStateProperty(
                type: .UInt16,
                value: UInt16(1)
            ),
            "ui32": KripkeStateProperty(
                type: .UInt32,
                value: UInt32(1)
            ),
            "ui64": KripkeStateProperty(
                type: .UInt64,
                value: UInt64(1)
            ),
            "f": KripkeStateProperty(
                type: .Float,
                value: Float(1.0)
            ),
            "f80": KripkeStateProperty(
                type: .Float80,
                value: Float80(1.0)
            ),
            "d": KripkeStateProperty(
                type: .Double,
                value: Double(1.0)
            ),
            "s": KripkeStateProperty(
                type: .String,
                value: "s"
            )
        ]
        let result = self.converter.convert(fromList: list)
        let expected: [String: Any] = [
            "b": true,
            "i": Int(1),
            "i8": Int8(1),
            "i16": Int16(1),
            "i32": Int32(1),
            "i64": Int64(1),
            "ui": UInt(1),
            "ui8": UInt8(1),
            "ui16": UInt16(1),
            "ui32": UInt32(1),
            "ui64": UInt64(1),
            "f": Float(1.0),
            "f80": Float80(1.0),
            "d": Double(1.0),
            "s": "s"
        ]
        XCTAssertEqual(expected.count, result.count)
        XCTAssertEqual(expected["b"] as? Bool, result["b"] as? Bool)
        XCTAssertEqual(expected["i"] as? Int, result["i"] as? Int)
        XCTAssertEqual(expected["i8"] as? Int8, result["i8"] as? Int8)
        XCTAssertEqual(expected["i16"] as? Int16, result["i16"] as? Int16)
        XCTAssertEqual(expected["i32"] as? Int32, result["i32"] as? Int32)
        XCTAssertEqual(expected["i64"] as? Int64, result["i64"] as? Int64)
        XCTAssertEqual(expected["ui"] as? UInt, result["ui"] as? UInt)
        XCTAssertEqual(expected["ui8"] as? UInt8, result["ui8"] as? UInt8)
        XCTAssertEqual(expected["ui16"] as? UInt16, result["ui16"] as? UInt16)
        XCTAssertEqual(expected["ui32"] as? UInt32, result["ui32"] as? UInt32)
        XCTAssertEqual(expected["ui64"] as? UInt64, result["ui64"] as? UInt64)
        XCTAssertEqual(expected["f"] as? Float, result["f"] as? Float)
        XCTAssertEqual(expected["f80"] as? Float80, result["f80"] as? Float80)
        XCTAssertEqual(expected["d"] as? Double, result["d"] as? Double)
        XCTAssertEqual(expected["s"] as? String, result["s"] as? String)
    }

}

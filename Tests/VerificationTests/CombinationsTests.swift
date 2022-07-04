/*
 * CombinationsTests.swift
 * Verification
 *
 * Created by Callum McColl on 24/2/21.
 * Copyright © 2021 Callum McColl. All rights reserved.
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

import XCTest

import KripkeStructure
import swiftfsm

@testable import Verification

class CombinationsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_bools() throws {
        let combinations = Combinations<Bool>()
        let expected = [false, true]
        let result = combinations.map { $0 }
        XCTAssertEqual(result, expected)
    }
    
    func test_integers() throws {
        let combinations = Combinations<Int8>()
        let expected: [Int8] = Array(Int8.min...Int8.max)
        let result = combinations.map { $0 }
        XCTAssertEqual(result, expected)
    }
    
    func test_snapshotSensors() throws {
        let fsm = SensorFiniteStateMachine()
        let combinations = Combinations(fsms: [AnyScheduleableFiniteStateMachine(fsm)])
        let expected: [[[Bool]]] = [
            [[false]],
            [[true]]
        ]
        let result = Array(combinations)
        XCTAssertEqual(expected.count, result.count)
        for (expected, result) in zip(expected, result) {
            guard let result = result as? [[Bool]] else {
                XCTFail("Cannot convert result to [[Bool]]")
                return
            }
            XCTAssertEqual(result.count, expected.count)
            XCTAssertEqual(result, expected)
        }
    }
    
    func test_snapshotSensorsIsEmpty() throws {
        let fsm = SensorFiniteStateMachine()
        fsm.sensors1.val = true
        fsm.currentState = fsm.exitState
        let combinations = Combinations(fsms: [AnyScheduleableFiniteStateMachine(fsm)])
        let expected: [[[Bool]]] = [
            [[]],
        ]
        let result = Array(combinations)
        XCTAssertEqual(expected.count, result.count)
        for (expected, result) in zip(expected, result) {
            guard let result = result as? [[Bool]] else {
                XCTFail("Cannot convert result to [[Bool]]")
                return
            }
            XCTAssertEqual(result.count, expected.count)
            XCTAssertEqual(result, expected)
        }
    }
    
    func test_struct() throws {
        let combinations = Combinations(reflecting: TestStruct())
        let expected: [(Bool, UInt8)] = [
            (false, 0), (false, 1), (false, 2), (false, 3), (false, 4),
            (false, 5), (false, 6), (false, 7), (false, 8), (false, 9),
            (false, 10), (false, 11), (false, 12), (false, 13), (false, 14),
            (false, 15), (false, 16), (false, 17), (false, 18), (false, 19),
            (false, 20), (false, 21), (false, 22), (false, 23), (false, 24),
            (false, 25), (false, 26), (false, 27), (false, 28), (false, 29),
            (false, 30), (false, 31), (false, 32), (false, 33), (false, 34),
            (false, 35), (false, 36), (false, 37), (false, 38), (false, 39),
            (false, 40), (false, 41), (false, 42), (false, 43), (false, 44),
            (false, 45), (false, 46), (false, 47), (false, 48), (false, 49),
            (false, 50), (false, 51), (false, 52), (false, 53), (false, 54),
            (false, 55), (false, 56), (false, 57), (false, 58), (false, 59),
            (false, 60), (false, 61), (false, 62), (false, 63), (false, 64),
            (false, 65), (false, 66), (false, 67), (false, 68), (false, 69),
            (false, 70), (false, 71), (false, 72), (false, 73), (false, 74),
            (false, 75), (false, 76), (false, 77), (false, 78), (false, 79),
            (false, 80), (false, 81), (false, 82), (false, 83), (false, 84),
            (false, 85), (false, 86), (false, 87), (false, 88), (false, 89),
            (false, 90), (false, 91), (false, 92), (false, 93), (false, 94),
            (false, 95), (false, 96), (false, 97), (false, 98), (false, 99),
            (false, 100), (false, 101), (false, 102), (false, 103), (false, 104),
            (false, 105), (false, 106), (false, 107), (false, 108), (false, 109),
            (false, 110), (false, 111), (false, 112), (false, 113), (false, 114),
            (false, 115), (false, 116), (false, 117), (false, 118), (false, 119),
            (false, 120), (false, 121), (false, 122), (false, 123), (false, 124),
            (false, 125), (false, 126), (false, 127), (false, 128), (false, 129),
            (false, 130), (false, 131), (false, 132), (false, 133), (false, 134),
            (false, 135), (false, 136), (false, 137), (false, 138), (false, 139),
            (false, 140), (false, 141), (false, 142), (false, 143), (false, 144),
            (false, 145), (false, 146), (false, 147), (false, 148), (false, 149),
            (false, 150), (false, 151), (false, 152), (false, 153), (false, 154),
            (false, 155), (false, 156), (false, 157), (false, 158), (false, 159),
            (false, 160), (false, 161), (false, 162), (false, 163), (false, 164),
            (false, 165), (false, 166), (false, 167), (false, 168), (false, 169),
            (false, 170), (false, 171), (false, 172), (false, 173), (false, 174),
            (false, 175), (false, 176), (false, 177), (false, 178), (false, 179),
            (false, 180), (false, 181), (false, 182), (false, 183), (false, 184),
            (false, 185), (false, 186), (false, 187), (false, 188), (false, 189),
            (false, 190), (false, 191), (false, 192), (false, 193), (false, 194),
            (false, 195), (false, 196), (false, 197), (false, 198), (false, 199),
            (false, 200), (false, 201), (false, 202), (false, 203), (false, 204),
            (false, 205), (false, 206), (false, 207), (false, 208), (false, 209),
            (false, 210), (false, 211), (false, 212), (false, 213), (false, 214),
            (false, 215), (false, 216), (false, 217), (false, 218), (false, 219),
            (false, 220), (false, 221), (false, 222), (false, 223), (false, 224),
            (false, 225), (false, 226), (false, 227), (false, 228), (false, 229),
            (false, 230), (false, 231), (false, 232), (false, 233), (false, 234),
            (false, 235), (false, 236), (false, 237), (false, 238), (false, 239),
            (false, 240), (false, 241), (false, 242), (false, 243), (false, 244),
            (false, 245), (false, 246), (false, 247), (false, 248), (false, 249),
            (false, 250), (false, 251), (false, 252), (false, 253), (false, 254),
            (false, 255),
            (true, 0), (true, 1), (true, 2), (true, 3), (true, 4),
            (true, 5), (true, 6), (true, 7), (true, 8), (true, 9),
            (true, 10), (true, 11), (true, 12), (true, 13), (true, 14),
            (true, 15), (true, 16), (true, 17), (true, 18), (true, 19),
            (true, 20), (true, 21), (true, 22), (true, 23), (true, 24),
            (true, 25), (true, 26), (true, 27), (true, 28), (true, 29),
            (true, 30), (true, 31), (true, 32), (true, 33), (true, 34),
            (true, 35), (true, 36), (true, 37), (true, 38), (true, 39),
            (true, 40), (true, 41), (true, 42), (true, 43), (true, 44),
            (true, 45), (true, 46), (true, 47), (true, 48), (true, 49),
            (true, 50), (true, 51), (true, 52), (true, 53), (true, 54),
            (true, 55), (true, 56), (true, 57), (true, 58), (true, 59),
            (true, 60), (true, 61), (true, 62), (true, 63), (true, 64),
            (true, 65), (true, 66), (true, 67), (true, 68), (true, 69),
            (true, 70), (true, 71), (true, 72), (true, 73), (true, 74),
            (true, 75), (true, 76), (true, 77), (true, 78), (true, 79),
            (true, 80), (true, 81), (true, 82), (true, 83), (true, 84),
            (true, 85), (true, 86), (true, 87), (true, 88), (true, 89),
            (true, 90), (true, 91), (true, 92), (true, 93), (true, 94),
            (true, 95), (true, 96), (true, 97), (true, 98), (true, 99),
            (true, 100), (true, 101), (true, 102), (true, 103), (true, 104),
            (true, 105), (true, 106), (true, 107), (true, 108), (true, 109),
            (true, 110), (true, 111), (true, 112), (true, 113), (true, 114),
            (true, 115), (true, 116), (true, 117), (true, 118), (true, 119),
            (true, 120), (true, 121), (true, 122), (true, 123), (true, 124),
            (true, 125), (true, 126), (true, 127), (true, 128), (true, 129),
            (true, 130), (true, 131), (true, 132), (true, 133), (true, 134),
            (true, 135), (true, 136), (true, 137), (true, 138), (true, 139),
            (true, 140), (true, 141), (true, 142), (true, 143), (true, 144),
            (true, 145), (true, 146), (true, 147), (true, 148), (true, 149),
            (true, 150), (true, 151), (true, 152), (true, 153), (true, 154),
            (true, 155), (true, 156), (true, 157), (true, 158), (true, 159),
            (true, 160), (true, 161), (true, 162), (true, 163), (true, 164),
            (true, 165), (true, 166), (true, 167), (true, 168), (true, 169),
            (true, 170), (true, 171), (true, 172), (true, 173), (true, 174),
            (true, 175), (true, 176), (true, 177), (true, 178), (true, 179),
            (true, 180), (true, 181), (true, 182), (true, 183), (true, 184),
            (true, 185), (true, 186), (true, 187), (true, 188), (true, 189),
            (true, 190), (true, 191), (true, 192), (true, 193), (true, 194),
            (true, 195), (true, 196), (true, 197), (true, 198), (true, 199),
            (true, 200), (true, 201), (true, 202), (true, 203), (true, 204),
            (true, 205), (true, 206), (true, 207), (true, 208), (true, 209),
            (true, 210), (true, 211), (true, 212), (true, 213), (true, 214),
            (true, 215), (true, 216), (true, 217), (true, 218), (true, 219),
            (true, 220), (true, 221), (true, 222), (true, 223), (true, 224),
            (true, 225), (true, 226), (true, 227), (true, 228), (true, 229),
            (true, 230), (true, 231), (true, 232), (true, 233), (true, 234),
            (true, 235), (true, 236), (true, 237), (true, 238), (true, 239),
            (true, 240), (true, 241), (true, 242), (true, 243), (true, 244),
            (true, 245), (true, 246), (true, 247), (true, 248), (true, 249),
            (true, 250), (true, 251), (true, 252), (true, 253), (true, 254),
            (true, 255)
        ]
        let result = combinations.map { ($0.bool, $0.num) }
        XCTAssertEqual(result.count, expected.count)
        for (index, ((rb, rn), (eb, en))) in zip(result, expected).enumerated() {
            XCTAssertEqual(rb, eb, "index: \(index)")
            XCTAssertEqual(rn, en, "index: \(index)")
        }
    }

    func test_boolsStructWithBoolInFSMWithOtherFSM() throws {
        let fsm = CombinationsFiniteStateMachine()
        let fsm2 = SimpleTimeConditionalFiniteStateMachine()
        let combinations = Combinations(fsms: [
            AnyScheduleableFiniteStateMachine(fsm),
            AnyScheduleableFiniteStateMachine(fsm2)
        ])
        let expected: [(Bool, Bool, Bool, Bool)] = [
            (false, false, false, false),
            (false, false, false, true),
            (false, false, true, false),
            (false, false, true, true),
            (false, true, false, false),
            (false, true, false, true),
            (false, true, true, false),
            (false, true, true, true),
            (true, false, false, false),
            (true, false, false, true),
            (true, false, true, false),
            (true, false, true, true),
            (true, true, false, false),
            (true, true, false, true),
            (true, true, true, false),
            (true, true, true, true)
        ]
        let result: [(Bool, Bool, Bool, Bool)] = combinations.map {
            let bools = $0[0][0] as! Bools
            let bool = $0[0][1] as! Bool
            XCTAssertTrue($0[1].isEmpty)
            return (bools.bool1, bools.bool2, bools.bool3, bool)
        }
        XCTAssertEqual(result.count, expected.count)
        for (index, ((rb1, rb2, rb3, rb4), (eb1, eb2, eb3, eb4))) in zip(result, expected).enumerated() {
            XCTAssertEqual(rb1, eb1, "b1 index: \(index)")
            XCTAssertEqual(rb2, eb2, "b2 index: \(index)")
            XCTAssertEqual(rb3, eb3, "b3 index: \(index)")
            XCTAssertEqual(rb4, eb4, "b4 index: \(index)")
        }
    }

    func test_boolsStructWithBoolInFSM() throws {
        let fsm = CombinationsFiniteStateMachine()
        let combinations = Combinations(fsms: [fsm].map(AnyScheduleableFiniteStateMachine.init))
        let expected: [(Bool, Bool, Bool, Bool)] = [
            (false, false, false, false),
            (false, false, false, true),
            (false, false, true, false),
            (false, false, true, true),
            (false, true, false, false),
            (false, true, false, true),
            (false, true, true, false),
            (false, true, true, true),
            (true, false, false, false),
            (true, false, false, true),
            (true, false, true, false),
            (true, false, true, true),
            (true, true, false, false),
            (true, true, false, true),
            (true, true, true, false),
            (true, true, true, true)
        ]
        let result: [(Bool, Bool, Bool, Bool)] = combinations.map {
            let bools = $0[0][0] as! Bools
            let bool = $0[0][1] as! Bool
            return (bools.bool1, bools.bool2, bools.bool3, bool)
        }
        XCTAssertEqual(result.count, expected.count)
        for (index, ((rb1, rb2, rb3, rb4), (eb1, eb2, eb3, eb4))) in zip(result, expected).enumerated() {
            XCTAssertEqual(rb1, eb1, "b1 index: \(index)")
            XCTAssertEqual(rb2, eb2, "b2 index: \(index)")
            XCTAssertEqual(rb3, eb3, "b3 index: \(index)")
            XCTAssertEqual(rb4, eb4, "b4 index: \(index)")
        }
    }
    
    func test_boolsStruct() throws {
        let combinations = Combinations(reflecting: Bools())
        let expected: [(Bool, Bool, Bool)] = [
            (false, false, false),
            (false, false, true),
            (false, true, false),
            (false, true, true),
            (true, false, false),
            (true, false, true),
            (true, true, false),
            (true, true, true)
        ]
        let result = combinations.map { ($0.bool1, $0.bool2, $0.bool3) }
        XCTAssertEqual(result.count, expected.count)
        for (index, ((rb1, rb2, rb3), (eb1, eb2, eb3))) in zip(result, expected).enumerated() {
            XCTAssertEqual(rb1, eb1, "b1 index: \(index)")
            XCTAssertEqual(rb2, eb2, "b2 index: \(index)")
            XCTAssertEqual(rb3, eb3, "b3 index: \(index)")
        }
    }
    
    func test_innerStruct() throws {
        let combinations = Combinations(reflecting: InnerStruct())
        let expected: [(Bool, Bool, Bool, Bool, Bool, Bool)] = [
            (false, false, false, false, false, false),
            (false, false, false, false, false, true),
            (false, false, false, false, true, false),
            (false, false, false, false, true, true),
            (false, false, false, true, false, false),
            (false, false, false, true, false, true),
            (false, false, false, true, true, false),
            (false, false, false, true, true, true),
            (false, false, true, false, false, false),
            (false, false, true, false, false, true),
            (false, false, true, false, true, false),
            (false, false, true, false, true, true),
            (false, false, true, true, false, false),
            (false, false, true, true, false, true),
            (false, false, true, true, true, false),
            (false, false, true, true, true, true),
            (false, true, false, false, false, false),
            (false, true, false, false, false, true),
            (false, true, false, false, true, false),
            (false, true, false, false, true, true),
            (false, true, false, true, false, false),
            (false, true, false, true, false, true),
            (false, true, false, true, true, false),
            (false, true, false, true, true, true),
            (false, true, true, false, false, false),
            (false, true, true, false, false, true),
            (false, true, true, false, true, false),
            (false, true, true, false, true, true),
            (false, true, true, true, false, false),
            (false, true, true, true, false, true),
            (false, true, true, true, true, false),
            (false, true, true, true, true, true),
            (true, false, false, false, false, false),
            (true, false, false, false, false, true),
            (true, false, false, false, true, false),
            (true, false, false, false, true, true),
            (true, false, false, true, false, false),
            (true, false, false, true, false, true),
            (true, false, false, true, true, false),
            (true, false, false, true, true, true),
            (true, false, true, false, false, false),
            (true, false, true, false, false, true),
            (true, false, true, false, true, false),
            (true, false, true, false, true, true),
            (true, false, true, true, false, false),
            (true, false, true, true, false, true),
            (true, false, true, true, true, false),
            (true, false, true, true, true, true),
            (true, true, false, false, false, false),
            (true, true, false, false, false, true),
            (true, true, false, false, true, false),
            (true, true, false, false, true, true),
            (true, true, false, true, false, false),
            (true, true, false, true, false, true),
            (true, true, false, true, true, false),
            (true, true, false, true, true, true),
            (true, true, true, false, false, false),
            (true, true, true, false, false, true),
            (true, true, true, false, true, false),
            (true, true, true, false, true, true),
            (true, true, true, true, false, false),
            (true, true, true, true, false, true),
            (true, true, true, true, true, false),
            (true, true, true, true, true, true),
        ]
        let result = combinations.map { ($0.strct1.bool1, $0.strct1.bool2, $0.strct1.bool3, $0.strct2.bool1, $0.strct2.bool2, $0.strct2.bool3) }
        XCTAssertEqual(result.count, expected.count)
        for (index, ((rb1, rb2, rb3, rb4, rb5, rb6), (eb1, eb2, eb3, eb4, eb5, eb6))) in zip(result, expected).enumerated() {
            XCTAssertEqual(rb1, eb1, "b1 index: \(index)")
            XCTAssertEqual(rb2, eb2, "b2 index: \(index)")
            XCTAssertEqual(rb3, eb3, "b3 index: \(index)")
            XCTAssertEqual(rb4, eb4, "b4 index: \(index)")
            XCTAssertEqual(rb5, eb5, "b5 index: \(index)")
            XCTAssertEqual(rb6, eb6, "b6 index: \(index)")
        }
    }
    
    func test_boolsInArray() throws {
        let combinations = Combinations(flatten: [Combinations(reflecting: Bools()), Combinations(reflecting: Bools())])
        let expected: [(Bool, Bool, Bool, Bool, Bool, Bool)] = [
            (false, false, false, false, false, false),
            (false, false, false, false, false, true),
            (false, false, false, false, true, false),
            (false, false, false, false, true, true),
            (false, false, false, true, false, false),
            (false, false, false, true, false, true),
            (false, false, false, true, true, false),
            (false, false, false, true, true, true),
            (false, false, true, false, false, false),
            (false, false, true, false, false, true),
            (false, false, true, false, true, false),
            (false, false, true, false, true, true),
            (false, false, true, true, false, false),
            (false, false, true, true, false, true),
            (false, false, true, true, true, false),
            (false, false, true, true, true, true),
            (false, true, false, false, false, false),
            (false, true, false, false, false, true),
            (false, true, false, false, true, false),
            (false, true, false, false, true, true),
            (false, true, false, true, false, false),
            (false, true, false, true, false, true),
            (false, true, false, true, true, false),
            (false, true, false, true, true, true),
            (false, true, true, false, false, false),
            (false, true, true, false, false, true),
            (false, true, true, false, true, false),
            (false, true, true, false, true, true),
            (false, true, true, true, false, false),
            (false, true, true, true, false, true),
            (false, true, true, true, true, false),
            (false, true, true, true, true, true),
            (true, false, false, false, false, false),
            (true, false, false, false, false, true),
            (true, false, false, false, true, false),
            (true, false, false, false, true, true),
            (true, false, false, true, false, false),
            (true, false, false, true, false, true),
            (true, false, false, true, true, false),
            (true, false, false, true, true, true),
            (true, false, true, false, false, false),
            (true, false, true, false, false, true),
            (true, false, true, false, true, false),
            (true, false, true, false, true, true),
            (true, false, true, true, false, false),
            (true, false, true, true, false, true),
            (true, false, true, true, true, false),
            (true, false, true, true, true, true),
            (true, true, false, false, false, false),
            (true, true, false, false, false, true),
            (true, true, false, false, true, false),
            (true, true, false, false, true, true),
            (true, true, false, true, false, false),
            (true, true, false, true, false, true),
            (true, true, false, true, true, false),
            (true, true, false, true, true, true),
            (true, true, true, false, false, false),
            (true, true, true, false, false, true),
            (true, true, true, false, true, false),
            (true, true, true, false, true, true),
            (true, true, true, true, false, false),
            (true, true, true, true, false, true),
            (true, true, true, true, true, false),
            (true, true, true, true, true, true),
        ]
        let result = combinations.map { ($0[0].bool1, $0[0].bool2, $0[0].bool3, $0[1].bool1, $0[1].bool2, $0[1].bool3) }
        XCTAssertEqual(result.count, expected.count)
        for (index, ((rb1, rb2, rb3, rb4, rb5, rb6), (eb1, eb2, eb3, eb4, eb5, eb6))) in zip(result, expected).enumerated() {
            XCTAssertEqual(rb1, eb1, "b1 index: \(index)")
            XCTAssertEqual(rb2, eb2, "b2 index: \(index)")
            XCTAssertEqual(rb3, eb3, "b3 index: \(index)")
            XCTAssertEqual(rb4, eb4, "b4 index: \(index)")
            XCTAssertEqual(rb5, eb5, "b5 index: \(index)")
            XCTAssertEqual(rb6, eb6, "b6 index: \(index)")
        }
    }

}

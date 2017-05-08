/*
 * MachineParserTests.swift 
 * tests 
 *
 * Created by Callum McColl on 14/01/2017.
 * Copyright © 2017 Callum McColl. All rights reserved.
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
@testable import Parsers

class MachineParserTests: XCTestCase {

    var parser: MachineParser!

    static var allTests: [(String, (MachineParserTests) -> () throws -> Void)] {
        return [
            ("test_parseReturnsAMachine", test_parseReturnsAMachine),
            ("test_parseReturnNilWhenFileIsNotFound", test_parseReturnNilWhenFileIsNotFound),
            ("test_parseReturnsPingPong", test_parseReturnsPingPong)
        ]
    }

    override func setUp() {
        super.setUp()
        self.parser = MachineParser()
        self.continueAfterFailure = false
    }

    func createPingPong() -> Machine {
        return Machine(
            globals: [],
            internals: [],
            fsms: [
                FSM(
                    name: "FSM1",
                    model: "MiPal",
                    states: [
                        State(
                            name: "Ping",
                            actions: [
                                "onEntry": "",
                                "main": "self.onExit()",
                                "onExit": "print(\"Ping\")\nself.count = self.count &+ 1"
                            ],
                            variables: [
                                Variable(label: "count", type: "Int8", value: "0")
                            ],
                            transitions: [
                                Transition(target: 1, expression: "true")
                            ]
                        ),
                        State(
                            name: "Pong",
                            actions: [
                                "onEntry": "",
                                "main": "self.onExit()",
                                "onExit": "print(\"Pong\")"
                            ],
                            variables: [],
                            transitions: [
                                Transition(target: 0, expression: "true")
                            ]
                        )
                    ],
                    variables: []
                )
            ]
        )
    }

    func test_parseReturnsAMachine() {
        let machine = self.parser.parse(file: "../PingPong.json")
        XCTAssertNotNil(machine)
    }

    func test_parseReturnNilWhenFileIsNotFound() {
        XCTAssertNil(self.parser.parse(file: "DOES_NOT_EXIT.json"))
    }

    func test_parseReturnsPingPong() {
        guard let pingPong = self.parser.parse(file: "../PingPong.json") else {
            XCTAssertNotNil(nil)
            return
        }
        XCTAssertEqual(pingPong, self.createPingPong())
    }

}

/*
 * SQLitePersistentStoreTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 16/5/2022.
 * Copyright © 2022 Callum McColl. All rights reserved.
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

import KripkeStructure
@testable import Verification
import XCTest

final class SQLitePersistentStoreTests: XCTestCase {

    var testName: String {
        self.name.dropFirst(2).dropLast().components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
    }

    var store: SQLitePersistentStore! = nil

    override func setUp() {
        self.continueAfterFailure = false
        do {
            self.store = try SQLitePersistentStore(named: testName)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_canAddPropertyList() {
        let propertyList = KripkeStatePropertyList(SensorFiniteStateMachine())
        do {
            let (id, state1) = try store.add(propertyList, isInitial: true)
            let state2 = try store.state(for: id)
            XCTAssertEqual(state1, state2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_canAddEdge() {
        let fsm = SensorFiniteStateMachine()
        let propertyList1 = KripkeStatePropertyList(fsm)
        fsm.sensors1.val = true
        let propertyList2 = KripkeStatePropertyList(fsm)
        let edge = KripkeEdge(clockName: fsm.name, constraint: .greaterThanEqual(value: 0), resetClock: true, takeSnapshot: true, time: 5, target: propertyList2)
        do {
            let (id1, _) = try store.add(propertyList1, isInitial: true)
            let (id2, _) = try store.add(propertyList2, isInitial: false)
            try store.add(edge: edge, to: id1)
            let state1 = try store.state(for: id1)
            XCTAssertEqual(state1.properties, propertyList1)
            XCTAssertEqual(state1.edges, [edge])
            let state2 = try store.state(for: id2)
            XCTAssertEqual(state2.properties, propertyList2)
            XCTAssertTrue(state2.edges.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}

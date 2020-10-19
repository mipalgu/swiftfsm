/*
 * ConstraintTests.swift 
 * LogicTests 
 *
 * Created by Callum McColl on 15/05/2020.
 * Copyright © 2020 Callum McColl. All rights reserved.
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
@testable import KripkeStructure

public class ConstraintTests: KripkeStructureTestCase {

    public static var allTests: [(String, (ConstraintTests) -> () throws -> Void)] {
        return [
            ("test_inverse", test_inverse),
            ("test_modusPonens", test_modusPonens),
            ("test_modusTollens", test_modusTollens),
            ("test_hypotheticalSyllogism", test_hypotheticalSyllogism),
            ("test_materialImplication", test_materialImplication),
            ("test_distributivity", test_distributivity),
            ("test_disjunctiveSyllogism", test_disjunctiveSyllogism),
            ("test_doubleNegation", test_doubleNegation),
            ("test_disjunctiveSimplification", test_disjunctiveSimplification),
            ("test_resolution", test_resolution),
            ("test_demorgans", test_demorgans),
            ("test_clampIntersectingRanges", test_clampIntersectingRanges),
            ("test_removesOverlappingRanges", test_removesOverlappingRanges),
            ("test_redundantOrs", test_redundantOrs)
        ]
    }
    
    let p: Constraint<UInt> = .equal(value: 3)
    let q: Constraint<UInt> = .equal(value: 5)
    let r: Constraint<UInt> = .equal(value: 7)

    public override func setUp() {}
    
    public func test_inverse() {
        XCTAssertEqual(
            Constraint<UInt>.lessThan(value: 0).inverse,
            Constraint<UInt>.greaterThanEqual(value: 0)
        )
        XCTAssertEqual(
            Constraint<UInt>.lessThanEqual(value: 0).inverse,
            Constraint<UInt>.greaterThan(value: 0)
        )
        XCTAssertEqual(
            Constraint<UInt>.equal(value: 0).inverse,
            Constraint<UInt>.notEqual(value: 0)
        )
        XCTAssertEqual(
            Constraint<UInt>.greaterThan(value: 0).inverse,
            Constraint<UInt>.lessThanEqual(value: 0)
        )
        XCTAssertEqual(
            Constraint<UInt>.greaterThanEqual(value: 0).inverse,
            Constraint<UInt>.lessThan(value: 0)
        )
        XCTAssertEqual(
            Constraint<UInt>.and(lhs: .equal(value: 0), rhs: .equal(value: 0)).inverse,
            Constraint<UInt>.or(lhs: .notEqual(value: 0), rhs: .notEqual(value: 0))
        )
        XCTAssertEqual(
            Constraint<UInt>.or(lhs: .equal(value: 0), rhs: .equal(value: 0)).inverse,
            Constraint<UInt>.and(lhs: .notEqual(value: 0), rhs: .notEqual(value: 0))
        )
        XCTAssertEqual(
            Constraint<UInt>.implies(lhs: .equal(value: 0), rhs: .equal(value: 0)).inverse,
            Constraint<UInt>.and(lhs: .equal(value: 0), rhs: .notEqual(value: 0))
        )
        XCTAssertEqual(
            Constraint<UInt>.not(value: .equal(value: 0)).inverse,
            Constraint<UInt>.equal(value: 0)
        )
    }
    
    public func test_modusPonens() {
        let constraint: Constraint<UInt> = .and(lhs: p, rhs: .implies(lhs: p, rhs: q))
        let expected: Constraint<UInt> = q
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_modusTollens() {
        let constraint: Constraint<UInt> = .and(lhs: .not(value: q), rhs: .implies(lhs: p, rhs: q))
        let expected: Constraint<UInt> = p.inverse
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_hypotheticalSyllogism() {
        let constraint: Constraint<UInt> = .and(lhs: .implies(lhs: p, rhs: q), rhs: .implies(lhs: q, rhs: r))
        let expected: Constraint<UInt> = .implies(lhs: p, rhs: r)
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_materialImplication() {
        let constraint: Constraint<UInt> = .or(lhs: .not(value: p), rhs: q)
        let expected: Constraint<UInt> = .implies(lhs: p, rhs: q)
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_distributivity() {
        let constraint: Constraint<UInt> = .and(lhs: .or(lhs: p, rhs: q), rhs: r)
        let expected: Constraint<UInt> = .or(lhs: .and(lhs: p, rhs: r), rhs: .and(lhs: q, rhs: r))
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_disjunctiveSyllogism() {
        let constraint: Constraint<UInt> = .and(lhs: .or(lhs: p, rhs: q), rhs: .not(value: p))
        let expected: Constraint<UInt> = q
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_doubleNegation() {
        let constraint: Constraint<UInt> = .not(value: .not(value: p))
        let expected: Constraint<UInt> = p
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_disjunctiveSimplification() {
        let constraint: Constraint<UInt> = .or(lhs: p, rhs: p)
        let expected: Constraint<UInt> = p
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_resolution() {
        let constraint: Constraint<UInt> = .and(lhs: .or(lhs: p, rhs: q), rhs: .or(lhs: .not(value: p), rhs: r))
        let expected: Constraint<UInt> = .or(lhs: q, rhs: r)
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_demorgans() {
        let constraint1: Constraint<UInt> = .not(value: .and(lhs: p, rhs: q))
        let expected1: Constraint<UInt> = .or(lhs: p.inverse, rhs: q.inverse)
        XCTAssertEqual(constraint1.reduced, expected1)
        let constraint2: Constraint<UInt> = .not(value: .or(lhs: p, rhs: q))
        let expected2: Constraint<UInt> = .and(lhs: p.inverse, rhs: q.inverse)
        XCTAssertEqual(constraint2.reduced, expected2)
    }
    
    public func test_clampIntersectingRanges() {
        let constraint: Constraint<UInt> = .and(lhs: .lessThanEqual(value: 3), rhs: .lessThanEqual(value: 2))
        let expected: Constraint<UInt> = .lessThanEqual(value: 2)
        XCTAssertEqual(constraint.reduced, expected)
        let complexConstraint: Constraint<UInt> = .and(lhs: .and(lhs: .greaterThan(value: 3), rhs: .lessThan(value: 10)), rhs: .greaterThan(value: 5))
        let complexExpected: Constraint<UInt> = .and(lhs: .greaterThanEqual(value: 6), rhs: .lessThanEqual(value: 9))
        XCTAssertEqual(complexConstraint.reduced, complexExpected)
    }
    
    public func test_removesOverlappingRanges() {
        let constraint: Constraint<UInt> = .or(lhs: .lessThanEqual(value: 3), rhs: .lessThanEqual(value: 2))
        let expected: Constraint<UInt> = .lessThanEqual(value: 3)
        XCTAssertEqual(constraint.reduced, expected)
    }
    
    public func test_redundantOrs() {
        let constraint: Constraint<UInt> = .or(lhs: .equal(value: 3), rhs: .greaterThan(value: 3))
        let expected: Constraint<UInt> = .greaterThanEqual(value: 3)
        XCTAssertEqual(constraint.reduced, expected)
    }

}

/*
 * Constraint.swift
 * KripkeStructure
 *
 * Created by Callum McColl on 14/5/20.
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

public enum Constraint<T: Comparable> {
    
    case lessThan(value: T)
    case lessThanEqual(value: T)
    case equal(value: T)
    case notEqual(value: T)
    case greaterThan(value: T)
    case greaterThanEqual(value: T)
    indirect case and(lhs: Constraint<T>, rhs: Constraint<T>)
    indirect case or(lhs: Constraint<T>, rhs: Constraint<T>)
    indirect case implies(lhs: Constraint<T>, rhs: Constraint<T>)
    indirect case not(value: Constraint<T>)
    
    var inverse: Constraint<T> {
        switch self {
        case .lessThan(let value):
            return .greaterThanEqual(value: value)
        case .lessThanEqual(let value):
            return .greaterThan(value: value)
        case .equal(let value):
            return .notEqual(value: value)
        case .notEqual(let value):
            return .equal(value: value)
        case .greaterThan(let value):
            return .lessThanEqual(value: value)
        case .greaterThanEqual(let value):
            return .lessThan(value: value)
        case .and(let lhs, let rhs):
            return .or(lhs: lhs.inverse, rhs: rhs.inverse)
        case .or(let lhs, let rhs):
            return .and(lhs: lhs.inverse, rhs: rhs.inverse)
        case .implies(let lhs, let rhs):
            return .and(lhs: lhs, rhs: rhs.inverse)
        case .not(let value):
            return value
        }
    }
    
    private var logicalReduced: Constraint<T> {
        func reduce(_ constraint: Constraint<T>) -> Constraint<T> {
            // Material Implication
            switch constraint {
            case .or(let lhs, let q):
                switch lhs {
                case .not(let p):
                    return reduce(.implies(lhs: p, rhs: q))
                default:
                    break
                }
            default:
                break
            }
            // Modus Ponens
            switch constraint {
            case .and(let p, rhs: let wrap):
                switch wrap {
                case .implies(let q, let r):
                    if q == p {
                        return reduce(r)
                    }
                default:
                    break
                }
            default:
                break
            }
            // Modus Tollens
            switch constraint {
            case .and(let lhs, let rhs):
                switch rhs {
                case .implies(let p, let q):
                    if lhs == .not(value: q) || lhs == q.inverse {
                        return reduce(.not(value: p))
                    }
                default:
                    break
                }
            default:
                break
            }
            // Hypothetical Syllogism
            switch constraint {
            case .and(let lhs, let rhs):
                switch lhs {
                case .implies(let p, let q):
                    switch rhs {
                    case .implies(let qq, let r):
                        if q == qq {
                            return reduce(.implies(lhs: p, rhs: r))
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            default:
                break
            }
            // Disjunctive Simplification.
            switch constraint {
            case .or(let p, let q):
                if p == q {
                    return reduce(p)
                }
            default:
                break
            }
            // Resolution.
            switch constraint {
            case .and(let lhs, let rhs):
                switch lhs {
                case .or(let p, let q):
                    switch rhs {
                    case .or(let pp, let r):
                        if pp == .not(value: p) {
                            return reduce(.or(lhs: q, rhs: r))
                        }
                        break
                    default:
                        break
                    }
                default:
                    break
                }
            default:
                break
            }
            // Disjunctive Syllogism
            switch constraint {
            case .and(let constraint, let r):
                switch constraint {
                case .or(let p, let q):
                    switch r {
                    case .not(let innerR):
                        if p != innerR {
                            break
                        }
                        return reduce(q)
                    default:
                        break
                    }
                default:
                    break
                }
                fallthrough
            default:
                break
            }
            //Distrubitivty
            switch constraint {
            case .and(let con, let r):
                switch con {
                case .or(let p, let q):
                    return reduce(.or(
                        lhs: .and(lhs: p, rhs: r),
                        rhs: .and(lhs: q, rhs: r)
                    ))
                default:
                    break
                }
            default:
                break
            }
            // Remove Negation.
            switch constraint {
            case .not(let value):
                return reduce(value.inverse)
            default:
                break
            }
            // Reduce sub constraints.
            switch constraint {
            case .and(let lhs, let rhs):
                return .and(lhs: reduce(lhs), rhs: reduce(rhs))
            case .or(let lhs, let rhs):
                return .or(lhs: reduce(lhs), rhs: reduce(rhs))
            case .implies(let lhs, let rhs):
                return .implies(lhs: reduce(lhs), rhs: reduce(rhs))
            case .not(let con):
                return .not(value: reduce(con))
            default:
                break;
            }
            return constraint
        }
        return reduce(self)
    }
    
    public func expression(
        referencing reference: String,
        lessThan: (String, String) -> String = { "\($0) < \($1)" },
        lessThanEqual: (String, String) -> String = { "\($0) <= \($1)" },
        equal: (String, String) -> String = { "\($0) == \($1)" },
        notEqual: (String, String) -> String = { "\($0) != \($1)" },
        greaterThan: (String, String) -> String = { "\($0) > \($1)" },
        greaterThanEqual: (String, String) -> String = { "\($0) >= \($1)" },
        and: (String, String) -> String = { "\($0) && \($1)" },
        or: (String, String) -> String = { "\($0) || \($1)" },
        implies: (String, String) -> String = { "\($0) -> \($1)" },
        not: (String) -> String = { "!\($0)" },
        group: (String) -> String = { "(\($0)" },
        label: (String) -> String = { $0 },
        value: (T) -> String = { "\($0)" }
    ) -> String {
        func expression(_ constraint: Constraint<T>) -> String {
            return constraint.expression(
                referencing: reference,
                lessThan: lessThan,
                lessThanEqual: lessThanEqual,
                equal: equal,
                notEqual: notEqual,
                greaterThan: greaterThan,
                greaterThanEqual: greaterThanEqual,
                and: and,
                or: or,
                not: not,
                group: group,
                label: label,
                value: value
            )
        }
        func groupIfNeeded(_ constraint: Constraint<T>) -> String {
            switch constraint {
            case .or, .and, .implies:
                return group(expression(constraint))
            default:
                return expression(constraint)
            }
        }
        switch self.reduced {
        case .lessThan(let val):
            return lessThan(reference, value(val))
        case .lessThanEqual(let val):
            return lessThanEqual(reference, value(val))
        case .equal(let val):
            return equal(reference, value(val))
        case .notEqual(let val):
            return notEqual(reference, value(val))
        case .greaterThan(let val):
            return greaterThan(reference, value(val))
        case .greaterThanEqual(let val):
            return greaterThanEqual(reference, value(val))
        case .and(let lhs, let rhs):
            return and(groupIfNeeded(lhs), groupIfNeeded(rhs))
        case .or(let lhs, let rhs):
            return or(groupIfNeeded(lhs), groupIfNeeded(rhs))
        case .implies(let lhs, let rhs):
            return implies(groupIfNeeded(lhs), groupIfNeeded(rhs))
        case .not(let constraint):
            return not(group(expression(constraint)))
        }
    }
    
}

extension Constraint: Equatable {}
extension Constraint: Hashable where T: Hashable {}

extension Constraint: CustomStringConvertible {
    
    public var description: String {
        return self.expression(referencing: "")
    }
    
}

extension Constraint {
    
    public var reduced: Constraint<T> {
        return self.logicalReduced
    }
    
}

extension Constraint where T: Numeric, T: FixedWidthInteger {
    
    private var numericReduced: Constraint<T> {
        func convertToRange(_ constraint: Constraint<T>) -> Range<T>? {
            switch constraint {
            case .lessThan(let value):
                return T.min..<value.advanced(by: -1)
            case .lessThanEqual(let value):
                return T.min..<value
            case .greaterThan(let value):
                if value == T.max {
                    return T.max..<T.max
                }
                return value.advanced(by: 1)..<T.max
            case .greaterThanEqual(let value):
                return value..<T.max
            case .and(let lhs, let rhs):
                guard let lRange = convertToRange(lhs), let rRange = convertToRange(rhs), rRange.overlaps(lRange) else {
                    return nil
                }
                let lowerBound = max(lRange.lowerBound, rRange.lowerBound)
                let upperBound = min(lRange.upperBound, rRange.upperBound)
                return Range(uncheckedBounds: (lowerBound, upperBound))
            default:
                return nil
            }
        }
        func reduce(_ constraint: Constraint<T>) -> Constraint<T> {
            // Clamp intersecting ranges.
            switch constraint {
            case .and(let lhs, let rhs):
                switch (lhs, rhs) {
                case (.lessThan, .lessThan), (.lessThanEqual, .lessThan), (.lessThan, .lessThanEqual), (.lessThanEqual, .lessThanEqual), (.greaterThan, .greaterThan), (.greaterThanEqual, .greaterThan), (.greaterThan, .greaterThanEqual), (.greaterThanEqual, .greaterThanEqual), (.and, _), (.or, _), (_, .and), (_, .or):
                    guard let lRange = convertToRange(lhs), let rRange = convertToRange(rhs), rRange.overlaps(lRange) else {
                        break
                    }
                    let lowerBound = max(lRange.lowerBound, rRange.lowerBound)
                    let upperBound = min(lRange.upperBound, rRange.upperBound)
                    return reduce(.and(lhs: .greaterThanEqual(value: lowerBound), rhs: .lessThanEqual(value: upperBound)))
                default:
                    break
                }
            default:
                break
            }
            // Remove overlapping ranges.
            switch constraint {
            case .or(let lhs, let rhs):
                guard let lRange = convertToRange(lhs), let rRange = convertToRange(rhs), rRange.overlaps(lRange) else {
                    break
                }
                let lowerBound = min(lRange.lowerBound, rRange.lowerBound)
                let upperBound = max(lRange.upperBound, rRange.upperBound)
                return reduce(.and(lhs: .greaterThanEqual(value: lowerBound), rhs: .lessThanEqual(value: upperBound)))
            default:
                break
            }
            // Remove p = <value> || p > <value + 1>
            switch constraint {
            case .or(let lhs, let rhs):
                switch (lhs, rhs) {
                case (.equal(let value), let rangeConstraint), (let rangeConstraint, .equal(let value)):
                    guard let range = convertToRange(rangeConstraint) else {
                        break
                    }
                    if range.lowerBound > value, range.lowerBound.advanced(by: -1) == value {
                        return reduce(.and(lhs: .greaterThanEqual(value: value), rhs: .lessThanEqual(value: range.upperBound)))
                    }
                    if range.upperBound < value, range.upperBound.advanced(by: 1) == value {
                        return reduce(.and(lhs: .greaterThanEqual(value: range.lowerBound), rhs: .lessThanEqual(value: value)))
                    }
                default:
                    break
                }
            default:
                break
            }
            // Remove less than equal to max
            switch constraint {
            case .and(let p, let q), .or(let p, let q):
                switch (p, q) {
                case (.lessThanEqual(value: T.max), _):
                    return reduce(q)
                case (_, .lessThanEqual(value: T.max)):
                    return reduce(p)
                default:
                    break
                }
            default:
                break
            }
            // Remove greater than equal to min
            switch constraint {
            case .and(let p, let q), .or(let p, let q):
                switch (p, q) {
                case (.greaterThanEqual(value: T.min), _):
                    return reduce(q)
                case (_, .greaterThanEqual(value: T.min)):
                    return reduce(p)
                default:
                    break
                }
            default:
                break
            }
            // Reduce sub constraints.
            switch constraint {
            case .and(let lhs, let rhs):
                return .and(lhs: reduce(lhs), rhs: reduce(rhs))
            case .or(let lhs, let rhs):
                return .or(lhs: reduce(lhs), rhs: reduce(rhs))
            case .implies(let lhs, let rhs):
                return .implies(lhs: reduce(lhs), rhs: reduce(rhs))
            case .not(let con):
                return .not(value: reduce(con))
            default:
                break;
            }
            return constraint
        }
        return reduce(self)
    }
    
    public var reduced: Constraint<T> {
        return self.logicalReduced.numericReduced
    }
    
}

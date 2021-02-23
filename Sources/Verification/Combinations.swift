/*
 * Combinations.swift
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

import swiftfsm
import KripkeStructure

struct Combinations<Element>: Sequence {
    
    private let iterator: () -> AnyIterator<Element>
    
    private init(iterator: @escaping () -> AnyIterator<Element>) {
        self.iterator = iterator
    }
    
    func erased() -> Combinations<Any> {
        return Combinations<Any> {
            let iterator = self.makeIterator()
            return AnyIterator<Any> {
                iterator.next() as Any?
            }
        }
    }
    
    func makeIterator() -> AnyIterator<Element> {
        return self.iterator()
    }
    
}

extension Combinations where Element == Bool {
    
    init() {
        self.iterator = {
            var value: Bool? = false
            return AnyIterator {
                guard let out = value else {
                    return nil
                }
                value = out ? nil : true
                return out
            }
        }
    }
    
}

extension Combinations where Element: FixedWidthInteger {
    
    init() {
        self.iterator = {
            var value: Element? = Element.min
            return AnyIterator {
                guard let out = value else {
                    return nil
                }
                value = out == Element.max ? nil : out.advanced(by: 1)
                return out
            }
        }
    }
    
}

extension Combinations where Element: FloatingPoint {
    
    init() {
        self.iterator = {
            var value: Element? = Element.greatestFiniteMagnitude
            return AnyIterator {
                guard let out = value, !out.isInfinite && !out.isNaN else {
                    return nil
                }
                value = out.nextDown
                return out
            }
        }
    }
    
}

extension Combinations where Element: ConvertibleFromDictionary {
    
    init(reflecting element: Element) {
        func flatten(_ combinations: [String: Combinations<Any>]) -> Combinations<[String: Any?]> {
            if combinations.isEmpty {
                return Combinations<[String: Any?]> {
                    var value: [String: Any]? = [:]
                    return AnyIterator {
                        guard let out = value else {
                            return nil
                        }
                        value = nil
                        return out
                    }
                }
            }
            let initial: [(String, Combinations<Any>)] = Array(combinations)
            let initialPos = initial.count - 1
            return Combinations<[String: Any?]> {
                var iterators = initial.map { ($0, $1.makeIterator()) }
                var pos = initialPos
                var current: [String: Any?] = Dictionary(uniqueKeysWithValues: iterators.map { ($0, $1.next()) })
                return AnyIterator {
                    if pos < 0 {
                        return nil
                    }
                    let out = current
                    var nextValue: Any?
                    while pos >= 0 {
                        nextValue = iterators[pos].1.next()
                        if nextValue != nil {
                            current[iterators[pos].0] = nextValue
                            break
                        }
                        iterators[pos].1 = initial[pos].1.makeIterator()
                        current[iterators[pos].0] = iterators[pos].1.next()
                        pos -= 1
                    }
                    if nextValue == nil {
                        return out
                    }
                    pos = initialPos
                    return out
                }
            }
            
        }
        func createFromProperties(_ properties: KripkeStatePropertyList) -> [String: Combinations<Any>] {
            return properties.properties.mapValues { (value: KripkeStateProperty) -> Combinations<Any> in
                switch value.type {
                case .Bool:
                    return Combinations<Bool>().erased()
                case .Int:
                    return Combinations<Int>().erased()
                case .Int8:
                    return Combinations<Int8>().erased()
                case .Int16:
                    return Combinations<Int16>().erased()
                case .Int32:
                    return Combinations<Int32>().erased()
                case .Int64:
                    return Combinations<Int64>().erased()
                case .UInt:
                    return Combinations<UInt>().erased()
                case .UInt8:
                    return Combinations<UInt8>().erased()
                case .UInt16:
                    return Combinations<UInt16>().erased()
                case .UInt32:
                    return Combinations<UInt32>().erased()
                case .UInt64:
                    return Combinations<UInt64>().erased()
                case .Compound(let compoundProperties):
                    return flatten(createFromProperties(compoundProperties)).erased()
                default:
                    fatalError("Attempting to create combinations of unsupported type: \(Element.self)")
                }
            }
        }
        let properties: KripkeStatePropertyList = KripkeStatePropertyList(element)
        let dictionaryCombinations = flatten(createFromProperties(properties))
        self.init() {
            let iterator = dictionaryCombinations.makeIterator()
            return AnyIterator { iterator.next().map { Element(fromDictionary: $0) } }
        }
    }
    
}

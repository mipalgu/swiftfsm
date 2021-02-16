/*
 * KripkeStatePropertyList.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 22/02/2016.
 * Copyright © 2016 Callum McColl. All rights reserved.
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

#if os(macOS)
import Darwin
#else
import Glibc
#endif

import Functional

public struct KripkeStatePropertyList {

    public fileprivate(set) var properties: [String: KripkeStateProperty]

    public var propertiesDictionary: [String: Any] {
        var d: [String: Any] = [String: Any](minimumCapacity: self.properties.count)
        self.properties.forEach {
            d[$0] = $1.value
        }
        return d
    }
    
    public init<T>(_ object: T) {
        self = MirrorKripkePropertiesRecorder().takeRecord(of: object)
    }

    public init(_ properties: [String: KripkeStateProperty] = [:]) {
        self.properties = properties
    }

    public subscript(key: String) -> KripkeStateProperty? {
        get {
            return self.properties[key]
        } set {
            self.properties[key] = newValue
        }
    }

}

extension KripkeStatePropertyList: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, KripkeStateProperty) ... ) {
        var ps: [String: KripkeStateProperty] = [:]
        ps.reserveCapacity(elements.count)
        elements.forEach {
            ps[$0] = $1
        }
        self.init(ps)
    }

}

extension KripkeStatePropertyList: Equatable {

    public static func == (lhs: KripkeStatePropertyList, rhs: KripkeStatePropertyList) -> Bool {
        if lhs.properties.count < rhs.properties.count {
            return false
        }
        return nil == zip(
            lhs.properties.sorted { $0.key < $1.key},
            rhs.properties.sorted { $0.key < $1.key }
        ).first { $0 != $1 }
    }

}

extension KripkeStatePropertyList: Hashable, CustomStringConvertible {

    public var description: String {
        return self.properties.sorted { $0.key < $1.key }.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.properties)
    }

}

extension KripkeStatePropertyList: Sequence {

    public typealias Element = Dictionary<String, KripkeStateProperty>.Element

    public func makeIterator() -> DictionaryIterator<String, KripkeStateProperty> {
        return self.properties.makeIterator()
    }

}

extension KripkeStatePropertyList: Collection {

    public typealias Index = Dictionary<String, KripkeStateProperty>.Index

    public var startIndex: Index {
        return self.properties.startIndex
    }

    public var endIndex: Index {
        return self.properties.endIndex
    }

    public subscript(index: Index) -> Element {
        return self.properties[index]
    }

    public func index(_ i: Index, offsetBy n: Int) -> Index {
        return self.properties.index(i, offsetBy: n)
    }

    public func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
        return self.properties.index(i, offsetBy: n, limitedBy: limit)
    }

    public func index(where predicate: @escaping (Element) throws -> Bool) rethrows -> Index? {
        return try self.properties.index(where: predicate)
    }

    public func index(after i: Index) -> Index {
        return self.properties.index(after: i)
    }

}

public extension KripkeStatePropertyList {

    func merged(_ other: KripkeStatePropertyList) -> KripkeStatePropertyList {
        return KripkeStatePropertyList(self.properties <| other.properties)
    }

}

/**
 *  Creates a new dictioanry where `lhs` is merged with `rhs`.
 *
 *  - Attention: If there are conflicting keys, `rhs` has priority.
 *
 *  - SeeAlso: `Dictionary.merged(_:)`.
 */
public func <| (
    lhs: KripkeStatePropertyList,
    rhs: KripkeStatePropertyList
) -> KripkeStatePropertyList {
    return lhs.merged(rhs)
}

/**
 *  Creates a new dictioanry where `lhs` is merged with `rhs`.
 *
 *  - Attention: If there are conflicting keys, `lhs` has priority.
 *
 *  - SeeAlso: `Dictionary.merged(_:)`.
 */
public func |> (
    lhs: KripkeStatePropertyList,
    rhs: KripkeStatePropertyList
) -> KripkeStatePropertyList {
    return rhs.merged(lhs)
}

/**
 *  Provides merge functionality for dictionaries.
 */
public extension Dictionary where Key == String, Value == KripkeStateProperty {

    /**
     *  Create a new `Dictionary` where the result is the merging of `other`
     *  with `self`.
     *
     *  - Attention: If there are conflicting keys, `other` has priority.
     */
    func merged(_ other: [String: KripkeStateProperty]) -> [String: KripkeStateProperty] {
        var d = [String: KripkeStateProperty](minimumCapacity: self.count + other.count)
        func add(key: String, val: KripkeStateProperty) {
            switch val.type {
            case .Compound(let list):
                guard let currentVal = d[key] else {
                    d[key] = val
                    return
                }
                switch currentVal.type {
                case .Compound(let currentList):
                    d[key] = KripkeStateProperty(type: .Compound(currentList.merged(list)), value: val.value)
                    return
                default:
                    d[key] = val
                    return
                }
            default:
                d[key] = val
                return
            }
        }
        self.forEach { (key, val) in add(key: key, val: val) }
        other.forEach { (key, val) in add(key: key, val: val) }
        return d
    }

}

public func <| (
    lhs: [String: KripkeStateProperty],
    rhs: [String: KripkeStateProperty]
) -> [String: KripkeStateProperty] {
    return lhs.merged(rhs)
}

public func |> (
    lhs: [String: KripkeStateProperty],
    rhs: [String: KripkeStateProperty]
) -> [String: KripkeStateProperty] {
    return rhs.merged(lhs)
}

/**
 *  The `Dictionary` merge operator with right priority.
 */
infix operator <| : LeftFunctionalPrecedence

/**
 *  The `Dictionary` merge operator with left priority.
 */
infix operator |> : LeftFunctionalPrecedence

/*
 * KripkeStateProperty.swift
 * swiftfsm
 *
 * Created by Callum McColl on 19/11/2015.
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

//swiftlint:disable force_cast
//swiftlint:disable cyclomatic_complexity

/**
 *  A property within a Kripke State.
 */
public struct KripkeStateProperty: Equatable, Codable {

    public enum CodingKeys: CodingKey {
        
        case type
        
        case value
        
    }
    
    /**
     *  The type of the property.
     */
    public let type: KripkeStatePropertyTypes

    /**
     *  The value of the property.
     */
    public let value: Any

    public var isEmptyCompound: Bool {
        type.isEmptyCompound
    }

    var defaultProperty: KripkeStateProperty {
        KripkeStateProperty(type: type.defaultType, value: type.defaultValue)
    }
    
    public init(_ value: Bool) {
        self.init(type: .Bool, value: value)
    }
    
    public init(_ value: Int) {
        self.init(type: .Int, value: value)
    }
    
    public init(_ value: Int8) {
        self.init(type: .Int8, value: value)
    }
    
    public init(_ value: Int16) {
        self.init(type: .Int16, value: value)
    }
    
    public init(_ value: Int32) {
        self.init(type: .Int32, value: value)
    }
    
    public init(_ value: Int64) {
        self.init(type: .Int64, value: value)
    }
    
    public init(_ value: UInt) {
        self.init(type: .UInt, value: value)
    }
    
    public init(_ value: UInt8) {
        self.init(type: .UInt8, value: value)
    }
    
    public init(_ value: UInt16) {
        self.init(type: .UInt16, value: value)
    }
    
    public init(_ value: UInt32) {
        self.init(type: .UInt32, value: value)
    }
    
    public init(_ value: UInt64) {
        self.init(type: .UInt64, value: value)
    }
    
    public init(_ value: Float) {
        self.init(type: .Float, value: value)
    }
    
    
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
    public init(_ value: Float80) {
        self.init(type: .Float80, value: value)
    }
#endif
    
    public init(_ value: Double) {
        self.init(type: .Double, value: value)
    }
    
    public init(_ value: String) {
        self.init(type: .String, value: value)
    }
    
    public init<S: Sequence>(_ value: S) {
        self.init(type: .Collection(value.map { KripkeStateProperty($0) }), value: value)
    }
    
    public init<T>(_ value: T?) {
        guard let unwrapped = value else {
            self.init(type: .Optional(nil), value: value as Any)
            return
        }
        let property = KripkeStateProperty(unwrapped)
        self.init(type: .Optional(property), value: value as Any)
    }
    
    public init(_ value: Any) {
        switch value {
        case let b as Bool:
            self.init(b)
        case let i as Int:
            self.init(i)
        case let i8 as Int8:
            self.init(i8)
        case let i16 as Int16:
            self.init(i16)
        case let i32 as Int32:
            self.init(i32)
        case let i64 as Int64:
            self.init(i64)
        case let u as UInt:
            self.init(u)
        case let u8 as UInt8:
            self.init(u8)
        case let u16 as UInt16:
            self.init(u16)
        case let u32 as UInt32:
            self.init(u32)
        case let u64 as UInt64:
            self.init(u64)
        case let f as Float:
            self.init(f)
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        case let f80 as Float80:
            self.init(f80)
#endif
        case let d as Double:
            self.init(d)
        case let s as String:
            self.init(s)
        default:
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                guard let (_, value) = mirror.children.first else {
                    self.init(type: .Optional(nil), value: Optional<Any>.none as Any)
                    return
                }
                self.init(type: .Optional(KripkeStateProperty(value)), value: Optional<Any>.some(value) as Any)
                return
            }
            if mirror.displayStyle == .collection || mirror.displayStyle == .set {
                let values = mirror.children.map { $0.value }
                self.init(type: .Collection(values.map { KripkeStateProperty($0) }), value: values)
                return
            }
            self.init(type: .Compound(KripkeStatePropertyList(value)), value: value)
        }
    }

    /**
     *  Create a new `KripkeStateProperty`.
     *
     *  - Parameter type: The type of the property.
     *
     *  - Parameter value: The value of the property.
     */
    public init(type: KripkeStatePropertyTypes, value: Any) {
        self.type = type
        self.value = value
    }

    public func contains<T: AnyObject>(object: T) -> Bool {
        if let other = value as? T, other === object {
            return true
        }
        return type.contains(object: object)
    }

    /**
     *  Is `other` equal to `self`?
     */
    public func equals(other: KripkeStateProperty) -> Bool {
        // Check if rhs property type matches
        if self.type != other.type {
            return false
        }
        switch self.type {
        case .EmptyCollection:
            switch other.type {
            case .EmptyCollection:
                return true
            default:
                return false
            }
        case .Collection(let llists):
            switch other.type {
            case .Collection(let rlists):
                if llists.count != rlists.count {
                    return false
                }
                return nil == zip(llists, rlists).first {
                    $0 != $1
                }
            default:
                return false
            }
        case .Compound(let llist):
            switch other.type {
            case .Compound(let rlist):
                return llist == rlist
            default:
                return false
            }
        case .Optional(let lprop):
            switch other.type {
            case .Optional(let rprop):
                return lprop == rprop
            default:
                return false
            }
        default:
            // Compare the values
            return self.equalValues(other: other)
        }
    }

    private func equalValues(other: KripkeStateProperty) -> Bool {
        if Swift.type(of: self.value) != Swift.type(of: other.value) {
            return false
        }
        // Cast the values to the correct type and perform the equality check.
        switch self.value {
        case is Bool:
            return self.value as? Bool == other.value as? Bool
        case is UInt:
            return self.value as? UInt == other.value as? UInt
        case is UInt8:
            return self.value as? UInt8 == other.value as? UInt8
        case is UInt16:
            return self.value as? UInt16 == other.value as? UInt16
        case is UInt32:
            return self.value as? UInt32 == other.value as? UInt32
        case is UInt64:
            return self.value as? UInt64 == other.value as? UInt64
        case is Int:
            return self.value as? Int == other.value as? Int
        case is Int8:
            return self.value as? Int8 == other.value as? Int8
        case is Int16:
            return self.value as? Int16 == other.value as? Int16
        case is Int32:
            return self.value as? Int32 == other.value as? Int32
        case is Int64:
            return self.value as? Int64 == other.value as? Int64
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        case is Float80:
            return self.value as? Float80 == other.value as? Float80
#endif
        case is Float:
            return self.value as? Float == other.value as? Float
        case is Double:
            return self.value as? Double == other.value as? Double
        case is String:
            return self.value as? String == other.value as? String
        default:
            return true
        }
    }

}

extension KripkeStateProperty: CustomStringConvertible {

    public var description: String {
        switch self.type {
        case .Bool:
            return (self.value as! Bool).description
        case .UInt:
            return (self.value as! UInt).description
        case .UInt8:
            return (self.value as! UInt8).description
        case .UInt16:
            return (self.value as! UInt16).description
        case .UInt32:
            return (self.value as! UInt32).description
        case .UInt64:
            return (self.value as! UInt64).description
        case .Int:
            return (self.value as! Int).description
        case .Int8:
            return (self.value as! Int8).description
        case .Int16:
            return (self.value as! Int16).description
        case .Int32:
            return (self.value as! Int32).description
        case .Int64:
            return (self.value as! Int64).description
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        case .Float80:
            return (self.value as! Float80).description
#endif
        case .Float:
            return (self.value as! Float).description
        case .Double:
            return (self.value as! Double).description
        case .String:
            return self.value as! String
        case .Collection(let ps):
            return ps.map { $0.description }.description
        case .Compound(let list):
            return list.description
        case .Optional(let prop):
            guard let prop = prop else {
                return "nil"
            }
            return prop.description
        case .EmptyCollection:
            return "[]"
        }
    }

}

extension KripkeStateProperty: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        switch self.type {
        case .Bool:
            hasher.combine((self.value as! Bool))
        case .UInt:
            hasher.combine((self.value as! UInt))
        case .UInt8:
            hasher.combine((self.value as! UInt8))
        case .UInt16:
            hasher.combine((self.value as! UInt16))
        case .UInt32:
            hasher.combine((self.value as! UInt32))
        case .UInt64:
            hasher.combine((self.value as! UInt64))
        case .Int:
            hasher.combine((self.value as! Int))
        case .Int8:
            hasher.combine((self.value as! Int8))
        case .Int16:
            hasher.combine((self.value as! Int16))
        case .Int32:
            hasher.combine((self.value as! Int32))
        case .Int64:
            hasher.combine((self.value as! Int64))
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        case .Float80:
            hasher.combine((self.value as! Float80))
#endif
        case .Float:
            hasher.combine((self.value as! Float))
        case .Double:
            hasher.combine((self.value as! Double))
        case .String:
            hasher.combine((self.value as! String))
        case .EmptyCollection:
            hasher.combine([Int]())
        case .Collection, .Compound, .Optional:
            break // hashing the type is enough to cover these cases
        }
    }

}

extension KripkeStateProperty {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeStr = try container.decode(String.self, forKey: .type)
        let type: KripkeStatePropertyTypes
        let value: Any
        switch typeStr {
        case "Bool":
            type = .Bool
            value = try container.decode(Bool.self, forKey: .value)
        case "Int":
            type = .Int
            value = try container.decode(Int.self, forKey: .value)
        case "Int8":
            type = .Int8
            value = try container.decode(Int8.self, forKey: .value)
        case "Int16":
            type = .Int16
            value = try container.decode(Int16.self, forKey: .value)
        case "Int32":
            type = .Int32
            value = try container.decode(Int32.self, forKey: .value)
        case "Int64":
            type = .Int64
            value = try container.decode(Int64.self, forKey: .value)
        case "UInt":
            type = .UInt
            value = try container.decode(UInt.self, forKey: .value)
        case "UInt8":
            type = .UInt8
            value = try container.decode(UInt8.self, forKey: .value)
        case "UInt16":
            type = .UInt16
            value = try container.decode(UInt16.self, forKey: .value)
        case "UInt32":
            type = .UInt32
            value = try container.decode(UInt32.self, forKey: .value)
        case "UInt64":
            type = .UInt64
            value = try container.decode(UInt64.self, forKey: .value)
            
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        case "Float80":
            type = .Float80
            value = try Float80(container.decode(Double.self, forKey: .value))
#endif
        case "Float":
            type = .Float
            value = try container.decode(Float.self, forKey: .value)
        case "Double":
            type = .Double
            value = try container.decode(Double.self, forKey: .value)
        case "String":
            type = .String
            value = try container.decode(String.self, forKey: .value)
        case "Collection":
            let props = try container.decode([KripkeStateProperty].self, forKey: .value)
            type = .Collection(props)
            value = props.map(\.value)
        case "Compound":
            let plist = try container.decode(KripkeStatePropertyList.self, forKey: .value)
            type = .Compound(plist)
            value = plist.properties.mapValues(\.value)
        case "Optional":
            let prop = try container.decode(KripkeStateProperty?.self, forKey: .value)
            type = .Optional(prop)
            value = prop?.value as Any
        case "EmptyCollection":
            type = .EmptyCollection
            value = ()
        default:
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.type, in: container, debugDescription: "Type is not an expected value: \(typeStr)")
        }
        self.init(type: type, value: value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch type {
        case .Collection:
            try container.encode("Collection", forKey: .type)
        case .Compound:
            try container.encode("Compound", forKey: .type)
        case .Optional:
            try container.encode("Optional", forKey: .type)
        default:
            try container.encode(type.typeString, forKey: .type)
        }
        switch self.type {
        case .Bool:
            try container.encode(self.value as! Bool, forKey: .value)
        case .UInt:
            try container.encode(self.value as! UInt, forKey: .value)
        case .UInt8:
            try container.encode(self.value as! UInt8, forKey: .value)
        case .UInt16:
            try container.encode(self.value as! UInt16, forKey: .value)
        case .UInt32:
            try container.encode(self.value as! UInt32, forKey: .value)
        case .UInt64:
            try container.encode(self.value as! UInt64, forKey: .value)
        case .Int:
            try container.encode(self.value as! Int, forKey: .value)
        case .Int8:
            try container.encode(self.value as! Int8, forKey: .value)
        case .Int16:
            try container.encode(self.value as! Int16, forKey: .value)
        case .Int32:
            try container.encode(self.value as! Int32, forKey: .value)
        case .Int64:
            try container.encode(self.value as! Int64, forKey: .value)
            
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        case .Float80:
            try container.encode(Double(self.value as! Float80), forKey: .value)
#endif
        case .Float:
            try container.encode(self.value as! Float, forKey: .value)
        case .Double:
            try container.encode(self.value as! Double, forKey: .value)
        case .String:
            try container.encode(self.value as! String, forKey: .value)
        case .Collection(let ps):
            try container.encode(ps, forKey: .value)
        case .Compound(let list):
            try container.encode(list, forKey: .value)
        case .Optional(let type):
            try container.encode(type, forKey: .value)
        case .EmptyCollection:
            try container.encodeNil(forKey: .value)
        }
    }
    
}

public func == (lhs: KripkeStateProperty, rhs: KripkeStateProperty) -> Bool {
    lhs.equals(other: rhs)
}

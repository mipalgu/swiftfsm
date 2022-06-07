/*
 * KripkeStatePropertyTypes.swift
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

//swiftlint:disable cyclomatic_complexity

/**
 *  Supported types for `KripkeStructure`s.
 */
public enum KripkeStatePropertyTypes: Equatable, Codable {
    case Bool
    case Int, Int8, Int16, Int32, Int64
    case UInt, UInt8, UInt16, UInt32, UInt64
    case Float, Float80, Double
    case String
    indirect case Optional(KripkeStateProperty?)
    case EmptyCollection
    case Collection([KripkeStateProperty])
    case Compound(KripkeStatePropertyList)

    var typeString: String {
        switch self {
        case .Bool: return "Bool"
        case .Int: return "Int"
        case .Int8: return "Int8"
        case .Int16: return "Int16"
        case .Int32: return "Int32"
        case .Int64: return "Int64"
        case .UInt: return "UInt"
        case .UInt8: return "UInt8"
        case .UInt16: return "UInt16"
        case .UInt32: return "UInt32"
        case .UInt64: return "UInt64"
        case .Float: return "Float"
        case .Float80: return "Float80"
        case .Double: return "Double"
        case .String: return "String"
        case .Optional: return "Optional"
        case .EmptyCollection: return "EmptyCollection"
        case .Collection: return "Collection"
        case .Compound: return "Compound"
        }
    }

    var isEmpty: Bool {
        switch self {
        case .EmptyCollection:
            return true
        case .Optional(let opt):
            return opt == nil
        case .Collection(let props):
            return props.isEmpty || !props.contains(where: { !$0.type.isEmpty })
        case .Compound(let props):
            return props.properties.isEmpty || !props.properties.values.contains { !$0.type.isEmpty }
        default:
            return false
        }
    }

    var defaultType: KripkeStatePropertyTypes {
        switch self {
        case .Bool,
            .Int, .Int8, .Int16, .Int32, .Int64,
            .UInt, .UInt8, .UInt16, .UInt32, .UInt64,
            .Float, .Float80, .Double,
            .String,
            .EmptyCollection:
            return self
        case .Optional:
            return .Optional(nil)
        case .Collection:
            return .Collection([])
        case .Compound:
            return .Compound(KripkeStatePropertyList())
        }
    }

    var defaultValue: Any {
        switch self {
        case .Bool:
            return false
        case .Int:
            return 0
        case .Int8:
            return Swift.Int8(0)
        case .Int16:
            return Swift.Int16(0)
        case .Int32:
            return Swift.Int32(0)
        case .Int64:
            return Swift.Int64(0)
        case .UInt:
            return Swift.UInt(0)
        case .UInt8:
            return Swift.UInt8(0)
        case .UInt16:
            return Swift.UInt16(0)
        case .UInt32:
            return Swift.UInt32(0)
        case .UInt64:
            return Swift.UInt64(0)
        case .Float:
            return Swift.Float(0)
        case .Float80:
            return Swift.Float80(0)
        case .Double:
            return 0.0
        case .String:
            return ""
        case .EmptyCollection:
            return Array<Any>()
        case .Optional:
            return Swift.Optional<Any>.none as Any
        case .Collection(let props):
            return props.map(\.type.defaultValue)
        case .Compound:
            return Dictionary<String, Any>()
        }
    }

    public func contains<T: AnyObject>(object: T) -> Bool {
        switch self {
        case .Compound(let plist):
            return plist.contains(object: object)
        case .Collection(let props):
            return props.contains(where: { $0.contains(object: object) })
        case .Optional(let prop):
            guard let prop = prop else {
                return false
            }
            return prop.contains(object: object)
        default:
            return false
        }
    }

}

extension KripkeStatePropertyTypes: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeString)
        switch self {
        case .Collection(let props):
            hasher.combine(props)
        case .Compound(let plist):
            hasher.combine(plist)
        case .Optional(let prop):
            hasher.combine(prop)
        default:
            break
        }
    }

}

/**
 *  Are two types equal?
 */
//swiftlint:disable:next function_body_length
public func == (lhs: KripkeStatePropertyTypes, rhs: KripkeStatePropertyTypes) -> Bool {
    switch (lhs, rhs) {
    case (.Bool, .Bool):
        return true
    case (.Int, .Int):
        return true
    case (.Int8, .Int8):
        return true
    case (.Int16, .Int16):
        return true
    case (.Int32, .Int32):
        return true
    case (.Int64, .Int64):
        return true
    case (.UInt, .UInt):
        return true
    case (.UInt8, .UInt8):
        return true
    case (.UInt16, .UInt16):
        return true
    case (.UInt32, .UInt32):
        return true
    case (.UInt64, .UInt64):
        return true
    case (.Float, .Float):
        return true
    case (.Float80, .Float80):
        return true
    case (.Double, .Double):
        return true
    case (.String, .String):
        return true
    case (.EmptyCollection, .EmptyCollection):
        return true
    case (let .Collection(p1), let .Collection(p2)):
        return p1 == p2
    case (let .Compound(c1), let .Compound(c2)):
        return c1 == c2
    case (.Optional(let lo), .Optional(let ro)):
        return lo == ro
    default:
        return false
    }
}

/*
 * MirrorKripkePropertiesRecorder.swift
 * KripkeStructure
 *
 * Created by Callum McColl on 08/06/2017.
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

import swiftfsm

//swiftlint:disable force_cast
//swiftlint:disable line_length

final class MirrorKripkePropertiesRecorder {

    init() {}

    func takeRecord(of object: Any) -> KripkeStatePropertyList? {
        return self._takeRecord(of: object, withMemoryCache: [])
    }

    func getKripkeStatePropertyType(_ val: Any) -> (KripkeStatePropertyTypes, Any)? {
        return self.getKripkeStatePropertyType(val, validValues: [val], withMemoryCache: [])
    }

    private func _takeRecord(
        of object: Any,
        withMemoryCache memoryCache: [AnyObject]
    ) -> KripkeStatePropertyList {
        let computedVars: [String: Any]
        let manipulators: [String: (Any) -> Any]
        let validValues: [String: [Any]]
        if let modifier = object as? KripkeVariablesModifier {
            computedVars = modifier.computedVars
            manipulators = modifier.manipulators
            validValues = modifier.validVars
        } else {
            computedVars = [:]
            manipulators = [:]
            validValues = [:]
        }
        return self.getPropertiesFromMirror(
            mirror: Mirror(reflecting: object),
            computedVars: computedVars,
            manipulators: manipulators,
            validValues: validValues,
            withMemoryCache: memoryCache
        )
    }

    /*
     *  Extract the properties from a mirror.
     *
     *  If the mirror has a superclassMirror then the superclasses properties
     *  are also extracted, giving the child values preference over the
     *  superclass values.
     */
    //swiftlint:disable:next function_body_length
    private func getPropertiesFromMirror(
        mirror: Mirror,
        computedVars: [String: Any] = [:],
        manipulators: [String: (Any) -> Any] = [:],
        validValues: [String: [Any]] = [:],
        withMemoryCache memoryCache: [AnyObject]
    ) -> KripkeStatePropertyList {
        var p = KripkeStatePropertyList()
        let parent: Mirror? = mirror.superclassMirror
        if nil != parent {
            p = self.getPropertiesFromMirror(
                mirror: parent!,
                validValues: validValues,
                withMemoryCache: memoryCache
            )
        }
        for (index, child) in mirror.children.enumerated() {
            let label = child.label ?? "\(index)"
            if let computedVal = computedVars[label] {
                p[label] = self.convertValue(
                    value: computedVal,
                    validValues: [computedVal],
                    withMemoryCache: memoryCache
                )
                continue
            }
            if let manipulator = manipulators[label] {
                p[label] = self.convertValue(
                    value: child.value,
                    validValues: [manipulator(child.value)],
                    withMemoryCache: memoryCache
                )
                continue
            }
            if nil != validValues[label] && true == validValues[label]!.isEmpty {
                continue
            }
            p[label] = self.convertValue(
                value: child.value,
                validValues: validValues[label],
                withMemoryCache: memoryCache
            )
        }
        for (key, val) in computedVars {
            if nil != p[key] {
                continue
            }
            if let dict = val as? [String: Any] {
                var out: [String: KripkeStateProperty] = [:]
                out.reserveCapacity(dict.count)
                for (k, v) in dict {
                    out[k] = self.convertValue(value: v, validValues: [v], withMemoryCache: memoryCache)
                }
                p[key] = KripkeStateProperty(type: .Compound(KripkeStatePropertyList(out)), value: dict)
                continue
            }
            p[key] = self.convertValue(
                value: val,
                validValues: [val],
                withMemoryCache: memoryCache
            )
        }
        return p
    }

    /*
    *  Convert the value to a KripkeStateProperty.
    */
    private func convertValue(
        value: Any,
        validValues: [Any]?,
        withMemoryCache memoryCache: [AnyObject]
    ) -> KripkeStateProperty? {
        guard let t = self.getKripkeStatePropertyType(
            value,
            validValues: validValues ?? [value],
            withMemoryCache: memoryCache
        ) else {
            return nil
        }
        return KripkeStateProperty(
            type: t.0,
            value: t.1
        )
    }

    /*
    *  Derive the KripkeStatePropertyType associated with a value.
    */
    //swiftlint:disable:next cyclomatic_complexity function_body_length
    private func getKripkeStatePropertyType(
        _ val: Any,
        validValues values: [Any],
        withMemoryCache memoryCache: [AnyObject]
    ) -> (KripkeStatePropertyTypes, Any)? {
        let mirror = Mirror(reflecting: val)
        // Check for collections.
        if mirror.displayStyle == Mirror.DisplayStyle.dictionary {
            var dict: [String: KripkeStateProperty] = Dictionary(minimumCapacity: mirror.children.count)
            var elements: [(Any, Any)] = []
            elements.reserveCapacity(mirror.children.count)
            mirror.children.forEach {
                guard let (key, value) = $0.value as? (Any, Any) else {
                    fatalError("Unable to convert dictionary elements to tuple.")
                }
                let keyStr = "\(key)"
                guard let type = self.getKripkeStatePropertyType(value, validValues: [value], withMemoryCache: memoryCache)?.0 else {
                    dict[keyStr] = KripkeStateProperty(type: .Compound(KripkeStatePropertyList()), value: [String: Any]())
                    return
                }
                dict[keyStr] = KripkeStateProperty(type: type, value: value)
                elements.append((key, value))
            }
            return (.Compound(KripkeStatePropertyList(dict)), elements)
        }
        if  mirror.displayStyle == Mirror.DisplayStyle.collection ||
            mirror.displayStyle == Mirror.DisplayStyle.set
        {
            if mirror.children.isEmpty {
                return (.EmptyCollection, mirror.children.map(\.value))
            }
            let elements = mirror.children.map {
                self.getKripkeStatePropertyType($0, validValues: values, withMemoryCache: memoryCache)
            }
            let first: (KripkeStatePropertyTypes, Any)
            if let temp = elements.first(where: { $0 != nil && !$0!.0.isEmpty }), let temp2 = temp {
                first = temp2
            } else if let temp = elements.first(where: { $0 != nil }), let temp2 = temp {
                first = temp2
            } else {
                first = (.Compound(KripkeStatePropertyList()), [String: Any]())
            }
            let defaultProp = KripkeStateProperty(type: first.0, value: first.1).defaultProperty
            return (
                .Collection(mirror.children.map {
                    self.convertValue(value: $0, validValues: values, withMemoryCache: memoryCache) ?? defaultProp
                }),
                elements.map { $0?.1 ?? first.0.defaultValue }
            )
        }
        // Check for optionals.
        if mirror.displayStyle == Mirror.DisplayStyle.optional {
            guard let (_, value) = mirror.children.first else {
                return (.Optional(nil), Optional<Any>.none as Any)
            }
            if
                let type = self.convertValue(value: value, validValues: values, withMemoryCache: memoryCache),
                let value = self.getKripkeStatePropertyType(value, validValues: values, withMemoryCache: memoryCache)?.1
            {
                return (
                    .Optional(type),
                    Any?.some(value) as Any
                )
            } else {
                return (.Optional(nil), Any?.none as Any)
            }
        }
        switch val {
        case is Bool:
            let val: Bool = val as! Bool
            if 1 == values.count {
                return (.Bool, values[0])
            }
            return (.Bool, values[val == false ? 0 : 1])
        case is Int:
            let values: [Int] = values as! [Int]
            let val: Int = val as! Int
            return (.Int, values[Int((val &+ values[0]) % values.count)])
        case is Int8:
            let values: [Int8] = values as! [Int8]
            let val: Int8 = val as! Int8
            let temp = values[Int((val &+ values[0]) % Int8(values.count))]
            return (.Int8, temp)
        case is Int16:
            let values: [Int16] = values as! [Int16]
            let val: Int16 = val as! Int16
            return (.Int16, values[Int((val &+ values[0]) % Int16(values.count))])
        case is Int32:
            let values: [Int32] = values as! [Int32]
            let val: Int32 = val as! Int32
            return (.Int32, values[Int((val &+ values[0]) % Int32(values.count))])
        case is Int64:
            let values: [Int64] = values as! [Int64]
            let val: Int64 = val as! Int64
            return  (.Int64, values[Int((val &+ values[0]) % Int64(values.count))])
        case is UInt:
            let values: [UInt] = values as! [UInt]
            let val: UInt = val as! UInt
            return  (.UInt, values[Int((val &+ values[0]) % UInt(values.count))])
        case is UInt8:
            let values: [UInt8] = values as! [UInt8]
            let val: UInt8 = val as! UInt8
            return  (.UInt8, values[Int((val &+ values[0]) % UInt8(values.count))])
        case is UInt16:
            let values: [UInt16] = values as! [UInt16]
            let val: UInt16 = val as! UInt16
            return  (.UInt16, values[Int((val &+ values[0]) % UInt16(values.count))])
        case is UInt32:
            let values: [UInt32] = values as! [UInt32]
            let val: UInt32 = val as! UInt32
            return  (.UInt32, values[Int((val &+ values[0]) % UInt32(values.count))])
        case is UInt64:
            let values: [UInt64] = values as! [UInt64]
            let val: UInt64 = val as! UInt64
            return  (.UInt64, values[Int((val &+ values[0]) % UInt64(values.count))])
        case is Float:
            let values: [Float] = values as! [Float]
            var val: Float = ((val as! Float) + values[0])
            val = val.truncatingRemainder(dividingBy: Float(values.count))
            return (
                .Float,
                values.lazy.map { abs(val - $0) }.lazy.sorted { $0 < $1 }.first!
            )
        case is Float80:
            let values: [Float80] = values as! [Float80]
            var val: Float80 = ((val as! Float80) + values[0])
            val = val.truncatingRemainder(dividingBy: Float80(values.count))
            return (
                .Float80,
                values.lazy.map { abs(val - $0) }.lazy.sorted { $0 < $1 }.first!
            )
        case is Double:
            let values: [Double] = values as! [Double]
            var val: Double = ((val as! Double) + values[0])
            val = val.truncatingRemainder(dividingBy: Double(values.count))
            return (
                .Double,
                values.lazy.map { abs(val - $0) }.lazy.sorted { $0 < $1 }.first!
            )
        case is String:
            if values.count == 1 {
                return (.String, values[0])
            }
            return (.String, val)
        default:
            var memoryCache = memoryCache
            let temp = val as AnyObject
            if nil != memoryCache.first(where: { $0 === temp }) {
                return (.Compound(KripkeStatePropertyList()), val)
            }
            memoryCache.append(temp)
            let value: Any = values.count == 1 ? values[0] : val
            let plist = self._takeRecord(of: value, withMemoryCache: memoryCache)
            if plist.isEmpty || !plist.contains(where: { !$0.value.isEmptyCompound}) {
                // Check for enums.
                if mirror.displayStyle == .enum {
                    return (.String, "\(val)")
                }
                return nil
            } else {
                return (.Compound(plist), value)
            }
        }
    }

}

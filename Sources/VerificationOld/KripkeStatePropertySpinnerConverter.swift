/*
 * KripkeStatePropertySpinnerConverter.swift 
 * FSM 
 *
 * Created by Callum McColl on 27/09/2016.
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

import KripkeStructure
import Utilities

//swiftlint:disable line_length

/**
 *  Provides a way to convert a `KripkeStateProperty` to a `Spinners.Spinner`.
 */
public class KripkeStatePropertySpinnerConverter: KripkeStatePropertySpinnerConverterType {

    private let spinners: Spinners

    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    fileprivate let runner = SpinnerRunner()

    /**
     *  Create a new `KripkeStatePropertySpinnerConverter`.
     *
     *  - Parameter spinners: Contains all the different `Spinners.Spinner`s.
     */
    public init(spinners: Spinners = Spinners()) {
        self.spinners = spinners
    }
    
    public func emptySpinner(from ksp: KripkeStateProperty) -> (Any, (Any) -> Any?) {
        let (initialValue, _) = self.convert(from: ksp)
        var spun = false
        let spinner: (Any) -> Any? = { element in
            if spun {
                return nil
            }
            defer { spun = true }
            return element
        }
        return (initialValue, spinner)
    }

    /**
     *  Convert a `KripkeStateProperty` to a `Spinners.Spinner`.
     *
     *  - Parameter from: The `KripkeStateProperty` that is being converted.
     *
     *  - Returns: A tuple where the first element is the starting value of the
     *  `Spinners.Spinner` and the second element is the `Spinners.Spinner`.
     */
    // swiftlint:disable force_cast
    // swiftlint:disable cyclomatic_complexity
    public func convert(from ksp: KripkeStateProperty) -> (Any, (Any) -> Any?) {
        switch ksp.type {
        case .Bool:
            return (false, { self.spinners.bool($0 as! Bool) })
        case .Int:
            return (Int.min, { self.spinners.int($0 as! Int) })
        case .Int8:
            return (Int8.min, { self.spinners.int8($0 as! Int8) })
        case .Int16:
            return (Int16.min, { self.spinners.int16($0 as! Int16) })
        case .Int32:
            return (Int32.min, { self.spinners.int32($0 as! Int32) })
        case .Int64:
            return (Int64.min, { self.spinners.int64($0 as! Int64) })
        case .UInt:
            return (UInt.min, { self.spinners.uint($0 as! UInt) })
        case .UInt8:
            return (UInt8.min, { self.spinners.uint8($0 as! UInt8) })
        case .UInt16:
            return (UInt16.min, { self.spinners.uint16($0 as! UInt16) })
        case .UInt32:
            return (UInt32.min, { self.spinners.uint32($0 as! UInt32) })
        case .UInt64:
            return (UInt64.min, { self.spinners.uint64($0 as! UInt64) })
        case .Float:
            return (-Float.infinity, { self.spinners.float($0 as! Float) })
        case .Float80:
            return (-Float80.infinity, { self.spinners.float80($0 as! Float80) })
        case .Double:
            return (-Double.infinity, { self.spinners.double($0 as! Double) })
        default:
            return (ksp.value, self.spinners.nilSpinner)
        }
    }

    fileprivate func convertCompound<T>(_ props: KripkeStatePropertyList, type: T.Type) -> (T, (T) -> T?)? {
        guard let ConvertibleType = T.self as? ConvertibleFromDictionary.Type else {
            return nil
        }
        var defaultProps: KripkeStatePropertyList = [:]
        var defaultValues: [String: Any] = [:]
        var spinners: [String: (Any) -> Any?] = [:]
        defaultValues.reserveCapacity(props.count)
        spinners.reserveCapacity(props.count)
        props.forEach {
            let (defaults, spinner) = self.convert(from: $1)
            let (type, value) = self.recorder.getKripkeStatePropertyType($1)
            defaultProps[$0] = KripkeStateProperty(type: type, value: value)
            defaultValues[$0] = defaults
            spinners[$0] = spinner
        }
        guard let defaultValue: T = ConvertibleType.init(fromDictionary: defaultValues) as? T else {
            return nil
        }
        return (defaultValue, {
            let latestProps = self.recorder.takeRecord(of: $0).sorted { $0.key < $1.key }
            guard let vs = self.runner.spin(
                index: latestProps.startIndex,
                vars: latestProps,
                defaultValues: defaultProps,
                spinners: spinners
            ) else {
                return nil
            }
            return ConvertibleType.init(fromDictionary: vs.propertiesDictionary) as? T
        })
    }

    public func convert<S: Sequence>(_ sequence: S) -> (AnySequence<S.Iterator.Element>, (AnySequence<S.Iterator.Element>) -> AnySequence<S.Iterator.Element>?)? {
        guard let data: [(String, S.Iterator.Element, (S.Iterator.Element) -> S.Iterator.Element?)] = sequence.enumerated().failMap({
            guard let (defaultValue, spinner) = self.convert($1) else {
                return nil
            }
            return ("\($0)", defaultValue, spinner)
        }) else {
            return nil
        }
        let defaultValues = KripkeStatePropertyList(Dictionary(uniqueKeysWithValues: data.lazy.map { (index, defaultValue, _) in
            let (type, value) = self.recorder.getKripkeStatePropertyType(defaultValue)
            return (index, KripkeStateProperty(type: type, value: value))
        }))
        let spinners: [String: (Any) -> Any?] = Dictionary(uniqueKeysWithValues: data.lazy.map { (index, _, spinner) in
            return (index, { ($0 as? S.Iterator.Element).flatMap(spinner) })
        })
        return (AnySequence(data.map { (_, value, _) in value }), { (sequence: AnySequence<S.Iterator.Element>) -> AnySequence<S.Iterator.Element>? in
            let (type, _) = self.recorder.getKripkeStatePropertyType(sequence)
            switch type {
            case .EmptyCollection:
                return nil
            case .Collection(let arr):
                let vars: [(key: String, value: KripkeStateProperty)] = Array(arr.enumerated().map { (offset, element) in
                    let (type, value) = self.recorder.getKripkeStatePropertyType(element)
                    return ("\(offset)", KripkeStateProperty(type: type, value: value))
                })
                guard
                    let props = self.runner.spin(
                        index: vars.startIndex,
                        vars: vars,
                        defaultValues: defaultValues,
                        spinners: spinners
                    ),
                    let newSequence = props.sorted(by: { $0.key < $1.key }).failMap({ $1.value as? S.Iterator.Element })
                else {
                    return nil
                }
                return AnySequence(newSequence)
            default:
                return nil
            }
        })
    }

    public func convert<T>(_ value: T) -> (T, (T) -> T?)? {
        let (type, kripkeValue) = self.recorder.getKripkeStatePropertyType(value)
        switch type {
        case .EmptyCollection:
            return (value, { _ in nil })
        case .Collection:
            return nil
            //return self.convert(collection.toArray())
        case .Compound(let props):
            return self.convertCompound(props, type: T.self)
        default:
            let (defaults, spinner) = self.convert(from: KripkeStateProperty(type: type, value: kripkeValue))
            guard let castDefaults = defaults as? T else {
                return nil
            }
            return (castDefaults, {
                guard let val = spinner($0) as? T else {
                    return nil
                }
                return val
            })
        }
    }

}

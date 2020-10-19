/*
 * PropertyExtractor.swift
 * ExternalVariables
 *
 * Created by Callum McColl on 15/10/18.
 * Copyright © 2018 Callum McColl. All rights reserved.
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

public final class PropertyExtractor<Formatter: PropertyFormatter> {

    public let formatter: Formatter

    public init(formatter: Formatter) {
        self.formatter = formatter
    }
    
    public func convert(label: String) -> String {
        return self.formatter.format(label: label)
    }

    public func extract(from list: KripkeStatePropertyList) -> [String: String] {
        let dict: Ref<[String: String]> = Ref(value: [:])
        self.convert(list, properties: dict)
        return dict.value
    }

    fileprivate func convert(
        _ list: KripkeStatePropertyList,
        properties: Ref<[String: String]>,
        prepend: String? = nil
    ) {
        let preLabel = prepend.map { $0 + "\(self.formatter.delimiter)" } ?? ""
        list.forEach { (key, property) in
            let label = self.formatter.format(label: preLabel + key)
            self.convert(property, properties: properties, label: label)
        }
    }

    fileprivate func convert(_ property: KripkeStateProperty, properties: Ref<[String: String]>, label: String) {
        switch property.type {
        case .Optional(let property):
            switch property {
            case .none:
                properties.value[label] = self.formatter.nilValue
            case .some(let prop):
                self.convert(prop, properties: properties, label: label)
            }
        case .EmptyCollection:
            return
        case .Collection(let props):
            for (index, property) in props.enumerated() {
                self.convert(property, properties: properties, label: label + "\(self.formatter.delimiter)"
                    + self.formatter.format(label: "\(index)"))
            }
        case .Compound(let list):
            self.convert(list, properties: properties, prepend: label)
        default:
            properties.value[label] = self.formatter.formatValue(from: property)
        }
    }

}

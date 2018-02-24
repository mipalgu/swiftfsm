/*
 * NuSMVPropertyExtractor.swift 
 * Verification 
 *
 * Created by Callum McColl on 24/02/2018.
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

public final class NuSMVPropertyExtractor {

    /*
     *  Used to seperate different names when creating namespaces.
     */
    fileprivate let delimiter: String

    public init(delimiter: String = "-") {
        self.delimiter = delimiter
    }

    public func extract(from list: KripkeStatePropertyList) -> [String: String] {
        var dict: [String: String] = [:]
        self.convert(list, properties: &dict)
        return dict
    }

    fileprivate func convert(
        _ list: KripkeStatePropertyList,
        properties: inout [String: String],
        prepend: String? = nil
    ) {
        let preLabel = prepend.map { $0 + self.delimiter } ?? ""
        list.forEach { (key, property) in
            let label = self.formatLabel(preLabel + key)
            self.convert(property, properties: &properties, label: label)
        }
    }

    fileprivate func convert(_ property: KripkeStateProperty, properties: inout [String: String], label: String) {
        switch property.type {
        case .Collection(let props):
            for (index, property) in props.enumerated() {
                self.convert(property, properties: &properties, label: label + self.delimiter + "\(index)")
            }
        case .Compound(let list):
            self.convert(list, properties: &properties, prepend: label)
        default:
            properties[label] = self.formatPropertyValue(property)
        }
    }

    fileprivate func formatLabel(_ label: String) -> String {
        guard let first = label.characters.first else {
            return ""
        }
        var str = ""
        if (first < "a" || first > "z") && (first < "A" || first > "Z") {
            str += "_"
        }
        str += label.characters.map({
            if $0 == "." {
                return self.delimiter
            }
            if ($0 < "a" || $0 > "z")
                && ($0 < "A" || $0 > "Z")
                && ($0 < "0" || $0 > "9")
                && $0 != "#"
                && $0 != "_"
                && $0 != "$"
                && $0 != "-" {
                return ""
            }
            return "\($0)"
        }).reduce("", +)
        return str
    }

    fileprivate func formatPropertyValue(_ property: KripkeStateProperty) -> String {
        let val: String = "\(property.value)"
        switch property.type {
        case .String:
            return "\"" + val + "\""
        case .Double, .Float, .Float80:
            return "F" + String(val.characters.map({ $0 == "." ? "_" : $0 }))
        default:
            return val
        }
    }

}

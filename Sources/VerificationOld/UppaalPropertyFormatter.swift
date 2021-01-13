/*
 * UppaalPropertyFormatter.swift
 * ModelChecking
 *
 * Created by Callum McColl on 29/08/20.
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
import KripkeStructureViews
import swiftfsm

public final class UppaalPropertyFormatter: PropertyFormatter {

    public let delimiter: Character
    
    private var lastId: Int = 0
    
    private var ids: [String: Int] = [:]
    
    private var labels: [Int: String] = [:]
    
    public var nilValue: String {
        return "\(self.fetchId("Nothing"))"
    }

    public init(delimiter: Character = "_") {
        self.delimiter = delimiter
    }

    public func format(label: String) -> String {
        guard let first = label.first else {
            return ""
        }
        var str = ""
        if (first < "a" || first > "z") && (first < "A" || first > "Z") {
            str += "_"
        }
        str += self.formatString(label)
        return str
    }

    public func formatValue(from property: KripkeStateProperty) -> String {
        let val: String = "\(property.value)"
        let prefix: String
        switch property.type {
        case .Double:
            prefix = "d_"
        case .Float:
            prefix = "f_"
        case .Float80:
            prefix = "f80_"
        case .String:
            prefix = "str_"
        case .Bool, .Int, .Int8, .Int16, .Int32, .Int64, .UInt, .UInt8, .UInt16, .UInt32, .UInt64:
            return val
        default:
            prefix = ""
        }
        return "\(self.fetchId(prefix + val))"
    }

    public func formatString(_ str: String) -> String {
        return str.lazy.map {
            if $0 == "." {
                return String(self.delimiter)
            }
            if ($0 < "a" || $0 > "z")
                && ($0 < "A" || $0 > "Z")
                && ($0 < "0" || $0 > "9")
            {
                return ""
            }
            return "\($0)"
        }.reduce("", +)
    }
    
    public func reset() {
        self.lastId = 0
        self.ids = [:]
        self.labels = [:]
    }
    
    public func fetchId(_ value: String) -> Int {
        guard let id = self.ids[value] else {
            defer { self.lastId += 1 }
            let lastId = self.lastId
            self.ids[value] = lastId
            self.labels[lastId] = value
            return lastId
        }
        return id
    }
    
    public func fetchLabel(_ str: String) -> String {
        guard let id = Int(str), let label = self.labels[id] else {
            fatalError("Unable to fetch label for id.")
        }
        return label
    }

}

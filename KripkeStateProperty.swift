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

/**
 *  A property within a Kripke State.
 */
public struct KripkeStateProperty: Equatable {
    
    var type: KripkeStatePropertyTypes
    
    var value: Any
    
    public init(type: KripkeStatePropertyTypes, value: Any) {
        self.type = type
        self.value = value
    }
    
    public func equals(other: KripkeStateProperty) -> Bool {
        // Check if rhs property type matches
        if (self.type != other.type) {
            return false
        }
        // Compare the values
        return self.equalValues(other: other)
    }
    
    private func equalValues(other: KripkeStateProperty) -> Bool {
        if (self.value.dynamicType != other.value.dynamicType) {
            return false
        }
        // Cast the values to the correct type and perform the equality check.
        switch (self.value) {
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
        case is Float80:
            return self.value as? Float80 == other.value as? Float80
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
        switch (self.value) {
        case is UInt:
            return (self.value as! UInt).description
        case is UInt8:
            return (self.value as! UInt8).description
        case is UInt16:
            return (self.value as! UInt16).description
        case is UInt32:
            return (self.value as! UInt32).description
        case is UInt64:
            return (self.value as! UInt64).description
        case is Int:
            return (self.value as! Int).description
        case is Int8:
            return (self.value as! Int8).description
        case is Int16:
            return (self.value as! Int16).description
        case is Int32:
            return (self.value as! Int32).description
        case is Int64:
            return (self.value as! Int64).description
        case is Float80:
            return (self.value as! Float80).description
        case is Float:
            return (self.value as! Float).description
        case is Double:
            return (self.value as! Double).description
        case is String:
            return self.value as! String
        default:
            return "Some"
        }
    }
    
}

extension KripkeStateProperty: Hashable {

    public var hashValue: Int {
        return String("\(self.value)").hashValue
    }

}

public func ==(lhs: KripkeStateProperty, rhs: KripkeStateProperty) -> Bool {
    return lhs.equals(other: rhs)
}

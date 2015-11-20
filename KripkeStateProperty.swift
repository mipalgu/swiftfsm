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
    
    var value: UnsafeMutablePointer<Void>
    
    public init(
        type: KripkeStatePropertyTypes,
        value: UnsafeMutablePointer<Void>
    ) {
        self.type = type
        self.value = value
    }
    
    public func equals(other: KripkeStateProperty) -> Bool {
        // Check if rhs property type matches
        if (self.type != other.type) {
            return false
        }
        // Check for nils
        if (nil == self.value || nil == other.value) {
            return (nil == self.value) == (nil == other.value)
        }
        // Compare the values
        return self.equalValues(other)
    }
    
    private func equalValues(other: KripkeStateProperty) -> Bool {
        // Cast the values to the correct type and perform the equality check.
        switch (self.type) {
        case .Bool:
            return UnsafeMutablePointer<Bool>(self.value).memory ==
                UnsafeMutablePointer<Bool>(other.value).memory
        case .Int:
            return UnsafeMutablePointer<Int>(self.value).memory ==
                UnsafeMutablePointer<Int>(other.value).memory
        case .Int8:
            return UnsafeMutablePointer<Int8>(self.value).memory ==
                UnsafeMutablePointer<Int8>(other.value).memory
        case .Int16:
            return UnsafeMutablePointer<Int16>(self.value).memory ==
                UnsafeMutablePointer<Int16>(other.value).memory
        case .Int32:
            return UnsafeMutablePointer<Int32>(self.value).memory ==
                UnsafeMutablePointer<Int32>(other.value).memory
        case .Int64:
            return UnsafeMutablePointer<Int64>(self.value).memory ==
                UnsafeMutablePointer<Int64>(other.value).memory
        case .UInt:
            return UnsafeMutablePointer<UInt>(self.value).memory ==
                UnsafeMutablePointer<UInt>(other.value).memory
        case .UInt8:
            return UnsafeMutablePointer<UInt8>(self.value).memory ==
                UnsafeMutablePointer<UInt8>(other.value).memory
        case .UInt16:
            return UnsafeMutablePointer<UInt16>(self.value).memory ==
                UnsafeMutablePointer<UInt16>(other.value).memory
        case .UInt32:
            return UnsafeMutablePointer<UInt32>(self.value).memory ==
                UnsafeMutablePointer<UInt32>(other.value).memory
        case .UInt64:
            return UnsafeMutablePointer<UInt64>(self.value).memory ==
                UnsafeMutablePointer<UInt64>(other.value).memory
        case .Float:
            return UnsafeMutablePointer<Float>(self.value).memory ==
                UnsafeMutablePointer<Float>(other.value).memory
        case .Float80:
            return UnsafeMutablePointer<Float80>(self.value).memory ==
                UnsafeMutablePointer<Float80>(other.value).memory
        case .Double:
            return UnsafeMutablePointer<Double>(self.value).memory ==
                UnsafeMutablePointer<Double>(other.value).memory
        case .String:
            return UnsafeMutablePointer<String>(self.value).memory ==
                UnsafeMutablePointer<String>(other.value).memory
        case .Some:
            return UnsafeMutablePointer<String>(self.value).memory ==
                UnsafeMutablePointer<String>(other.value).memory
        }
    }
    
}

public func ==(lhs: KripkeStateProperty, rhs: KripkeStateProperty) -> Bool {
    return lhs.equals(rhs)
}

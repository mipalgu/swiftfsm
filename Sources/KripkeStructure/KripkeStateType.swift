/*
 * KripkeStateType.swift
 * swiftfsm
 *
 * Created by Callum McColl on 11/11/2015.
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
 *  Provides implementation details for `KripkeState`s.
 *
 *  - Warning: Do not use this type directly.  Instead use `KripkeState`.
 */
public protocol _KripkeStateType: class, Equatable {
    
    var isInitial: Bool { get }

    var properties: KripkeStatePropertyList { get }

    var edges: Set<KripkeEdge> { get }

}

extension _KripkeStateType where Self: CustomStringConvertible, Self: Hashable {

    public var description: String {
        var str: String = ""
        str += "initial: \(self.isInitial),\n"
        //str += "previous = \(self.previous?.state)\n"
        str += "properties: {\n"
        str += self.properties.description
        str += "\n},\n"
        str += "effects: [\n"
        str += (self.edges.first?.description ?? "") + self.edges.dropFirst().reduce("") {
            $0 + ",\n    " + $1.description
        }
        str += "\n}"
        return str
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isInitial)
        hasher.combine(properties)
        hasher.combine(edges)
    }

}

extension _KripkeStateType where Self: CustomDebugStringConvertible {

    public var debugDescription: String {
        var str: String = ""
        str += "properties: {\n"
        str += self.properties.description
        str += "\n}"
        return str
    }

}

/**
 *  Compare KripkeStates for equality.
 *
 *  This does not compare the previous property as a state is considered equal no
 *  matter if it transitions to a different state.
 */
public func ==<T: _KripkeStateType, U: _KripkeStateType>(
   lhs: T,
   rhs: U
) -> Bool {
    if lhs.isInitial != rhs.isInitial {
        return false
    }
    if lhs.edges.count != rhs.edges.count {
        return false
    }
    return lhs.properties == rhs.properties &&
        nil == lhs.edges.first { false == rhs.edges.contains($0) }
}

public protocol KripkeStateType: _KripkeStateType,
    CustomStringConvertible,
    CustomDebugStringConvertible,
    Hashable {}

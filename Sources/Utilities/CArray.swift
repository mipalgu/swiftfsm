/*
 * CArray.swift 
 * FSM 
 *
 * Created by Callum McColl on 19/03/2016.
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

/**
 *  A C array wrapper.
 *
 *  When attempting to use C arrays swift interprets them as tuples.  Therefore
 *  if I reference an int C array with a length of 4, I get a tuple containing
 *  4 ints: (Int, Int, Int, Int).
 *
 *  This becomes combersome as we would like to be able to use them just like
 *  normal Swift arrays.  The CArray wrapper provides this functionality.
 */
public struct CArray<T> {

    /**
     *  The type of the elements.
     */
    public typealias Element = T

    /**
     *  A pointer to the first element in the array.
     */
    internal var p: UnsafeMutablePointer<Element>?

    /**
     *  The total length of the array.
     */
    internal var length: Int

    /**
     *  Create an array from a reference to the first element.
     *
     *  This may be helpful we attempting to create a CArray from a tuple.
     *  Simply pass a reference to the first element in the tuple and the size
     *  of the tuple to create the CArray.
     *
     *  - Parameters:
     *      - first: The first element in the array.
     *      - length: The total length of the array.
     */
    public init(first: inout Element, length: Int = 1) {
        self.init(
            p: withUnsafeMutablePointer(to: &first, { $0 }),
            length: length
        )
    }

    /**
     *  Create the CArray from an UnsafeMutablePointer to the first element.
     *
     *  - Parameters:
     *      - p: The UnsafeMutablePointer to the first element.
     *      - length: The length of the array.
     */
    public init(p: UnsafeMutablePointer<Element>? = nil, length: Int = 0) {
        self.p = p
        self.length = length
    }

}

/**
 *  Make the CArray a Sequence.
 *
 *  This will allow operations such as map and filter to be used.
 */
extension CArray: Sequence {

    /**
     *  The iterator that generates each element with a call to next().
     */
    public typealias Iterator = AnyIterator<Element>

    /**
     *  Create the iterator that iterates over the elements in the array..
     *
     *  - Returns: the newly created iterator.
     */
    public func makeIterator() -> AnyIterator<Element> {
        if nil == self.p {
            return AnyIterator { nil }
        }
        var pos: Int = 0
        return AnyIterator {
            if pos >= self.length {
                return nil
            }
            let v: Element = self.p![pos]
            pos += 1
            return v
        }
    }

}

/**
 *  Make the CArray a Collection.
 *
 *  This allows modification/retrieval of elements through indexes.
 */
extension CArray: Collection {

    /**
     *  The index type - just an Int.
     */
    public typealias Index = Int

    /**
     *  The first element is at position 0 in the array.
     */
    public var startIndex: Int {
        return 0
    }

    /**
     *  The last element is at `length` - 1 in the array..
     */
    public var endIndex: Int {
        return length
    }

    /**
     *  Access the element at the specific position.
     *
     *  - Parameter i: The position of the element in the array to access.
     *
     *  - Complexity: O(1)
     *
     *  - Precondition: 0 <= `i` < `length`
     */
    public subscript(i: Int) -> Element {
        get {
            return p![i]
        } set {
            if i >= self.length {
                fatalError("Array index out of bounds")
            }
            p![i] = newValue
        }
    }

    /**
     *  Returns the position immediately after the given index.
     *
     *  - Parameter i: A valid index of the `CArray`.
     *
     *  - Returns: The index value immediatly after `i`.
     */
    public func index(after i: Index) -> Index {
        return i + 1
    }

}

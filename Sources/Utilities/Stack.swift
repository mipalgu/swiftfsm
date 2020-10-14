/*
 * Stack.swift 
 * FSM 
 *
 * Created by Callum McColl on 16/04/2016.
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
 *  A LIFO `Stack`.
 */
public struct Stack<T> {

    /**
     *  The type of the elements within the `Stack`.
     */
    public typealias Element = T

    private var data: [Element] = []

    /**
     *  The number of `Element`s within the `Stack`.
     */
    public var count: Int {
        return self.data.count
    }

    /**
     *  Is the `Stack` empty?
     */
    public var isEmpty: Bool {
        return self.data.isEmpty
    }

    /**
     *  Create an empty `Stack`.
     */
    public init() {}

    /**
     *  Remove all elements from the `Stack`.
     */
    public mutating func clear() {
        self.data = []
    }

    /**
     *  Retrieve the top `Element` without removing it.
     */
    public func peek() -> Element? {
        return data.first
    }

    /**
     *  Remove the top `Element` off the `Stack`.
     *
     *  - Precondition: The `Stack` is not empty.
     *
     *  - Postcondition: The top most `Element` is removed.
     *
     *  - Returns: The top most `Element`.
     */
    public mutating func pop() -> Element {
        return data.removeFirst()
    }

    /**
     *  Place an `Element` on top of the `Stack`.
     *
     *  - Parameter _: The new `Element`
     */
    public mutating func push(_ newElement: Element) {
        self.data.insert(newElement, at: 0)
    }

}

extension Stack: Sequence {

    public typealias Iterator = Stack

    public func makeIterator() -> Stack<Element> {
        return self
    }

}

extension Stack: IteratorProtocol {

    public mutating func next() -> Element? {
        if nil == self.peek() {
            return nil
        }
        return self.pop()
    }

}

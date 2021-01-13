/*
 * CycleDetector.swift 
 * FSM 
 *
 * Created by Callum McColl on 23/10/2016.
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
 *  Conforming types are responsible for detecting cycles within sequences.
 *
 *  The general procedure for using a `CycleDetector` is to create a `Data`
 *  variable that you would initialize to `initialData`.  You would then
 *  pass every `Element` within the sequence into `inCycle(data:element:)`
 *  and update the `Data` variable with the new values that are returned
 *  from `inCycle(data:element:)`.
 *
 */
public protocol CycleDetector {

    /**
     *  Cycle detector generally use some data structures to keep track of
     *  nodes that they have already seen in the sequence.  A `CycleDetector`
     *  therefore supplies this with the `Data` associated type.
     *
     *  Types that use `CycleDetector`s should start with the `initialData` and
     *  then pass the `Data` to `inCycle(data:,element:)` so that the
     *  `CycleDetector` can keep track of which `Element`s it has seen before.
     */
    associatedtype Data

    /**
     *  The type of the elements of the sequence.
     *
     *  Different `CycleDetectors` will have different restrictions of the 
     *  types that are supported for the elements of the sequence.  For instance
     *  a hash table would require the Elements to be `Hashable` in order to
     *  store them within the hash table.  This way they can specify their
     *  restrictions using the `Element` associated type.
     */
    associatedtype Element

    /**
     *  The starting `Data` structure.
     */
    var initialData: Data { get }

    /**
     *  Uses the current `Data` to inspect `element` and determine whether it
     *  has appeared before.
     *
     *  - Parameter data: The current `Data` of the sequence.
     *
     *  - Parameter element: The current `Element` within the sequence.
     *
     *  - Returns: Whether a cycle has been found.
     */
    func inCycle(data: inout Data, element: Element) -> Bool

}

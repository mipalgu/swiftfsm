/*
 * LeastLaxityDispatchTable.swift
 * swiftfsm
 *
 * Created by Callum McColl on 27/10/2015.
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

public class LeastLaxityDispatchTable: DispatchTable {
    
    private var index: Int = 0
    private var items: [Dispatchable]
    private var laxities: [Int]
    
    public init(items: [Dispatchable] = []) {
        self.items = items
        self.laxities = []
        self.reorganize()
    }
    
    public func addItem(item: Dispatchable) {
        self.items.append(item)
        self.laxities.append(self.calculateLaxity(item))
    }
    
    public func advance() {
        self.index = ++self.index % self.items.count
        if (0 == self.index) {
            self.reorganize()
        }
    }
    
    public func count() -> UInt {
        return UInt(self.items.count)
    }
    
    public func empty() -> Bool {
        return 0 == self.count()
    }
    
    public func get() -> Dispatchable {
        return self.get(self.index)
    }
    
    public func get(index: Int) -> Dispatchable {
        return self.items[index]
    }
    
    public func next() -> Dispatchable {
        self.advance()
        return self.items[self.index]
    }
    
    public func remove() {
        self.remove(self.index)
    }
    
    public func remove(index: Int) {
        self.items.removeAtIndex(index)
        self.laxities.removeAtIndex(index)
    }
    
    private func calculateLaxity(item: Dispatchable) -> Int {
        return Int(item.timeout) - Int(item.item.worstCaseExecutionTime)
    }
    
    private func place(item: Dispatchable) {
        let laxity: Int = self.calculateLaxity(item)
        for (var i: Int = 0; i < self.laxities.count; i++) {
            if (self.laxities[i] < laxity ) {
                continue
            }
            self.laxities.insert(laxity, atIndex: i)
            self.items.insert(item, atIndex: i)
            return
        }
        self.items.append(item)
        self.laxities.append(laxity)
    }
    
    private func reorganize() {
        let temp = self.items
        self.items = []
        self.laxities = []
        for d: Dispatchable in temp {
            self.place(d)
        }
    }
    
    
    
}
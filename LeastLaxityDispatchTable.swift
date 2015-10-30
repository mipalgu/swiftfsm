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

public class LeastLaxityDispatchTable: StaticDispatchTable {
    
    private let concurrentItems: Int
    private var dispatchQueues: [Array<Dispatchable>]
    private var indexes: [Int]
    private var filled: Int
    
    public init(items: [Dispatchable] = [], concurrentItems: UInt) {
        self.concurrentItems = Int(concurrentItems)
        self.dispatchQueues = Array<[Dispatchable]>(
            count: self.concurrentItems,
            repeatedValue: []
        )
        self.indexes = Array<Int>(count: self.concurrentItems, repeatedValue: 0)
        self.filled = 0
        super.init(items: items)
        self.reorganize()
    }
    
    public override func advance() {
        super.advance()
        if (0 == super.index) {
            self.reorganize()
        }
    }
    
    public override func next() -> Dispatchable {
        let index: Int = self.index % self.filled
        let d: Dispatchable = self.dispatchQueues[index][self.indexes[index]]
        self.indexes[index] = (self.indexes[index] + 1) % self.dispatchQueues[index].count
        self.advance()
        return d
    }
    
    public override func remove() {
        super.remove()
        self.reorganize()
    }
    
    public override func remove(index: Int) {
        super.remove(index)
        self.reorganize()
    }
    
    private func calculateLaxity(d: Dispatchable) -> Int {
        return Int(d.timeout) - Int(d.item.worstCaseExecutionTime)
    }
    
    private func reorganize() {
        if (super.items.count < 1) {
            return
        }
        super.items.sortInPlace { calculateLaxity($0) < calculateLaxity($1) }
        self.clearDispatchQueues()
        self.fillDispatchQueues()
    }
    
    private func clearDispatchQueues() {
        self.indexes = self.indexes.map({_ in 0})
        self.dispatchQueues = self.dispatchQueues.map({_ in []})
    }
    
    private func fillDispatchQueues() {
        var j: Int = 0
        for i: Int in 0 ... Int(self.count()) - 1 {
            let qIndex: Int = self.indexes[j]++
            self.dispatchQueues[j].append(self.items[i])
            if (qIndex != 0) {
                let lastItem: Dispatchable = self.dispatchQueues[j][qIndex - 1]
                self.dispatchQueues[j][qIndex].startTime =
                    lastItem.startTime + lastItem.timeout
            } else {
                self.dispatchQueues[j][qIndex].startTime = 0
            }
            j = (j + 1) % self.dispatchQueues.count
        }
        self.filled = Int(self.count()) < self.concurrentItems ? Int(self.count()) : self.concurrentItems
        self.indexes = self.indexes.map({_ in 0})
        self.index = 0
    }
    
}
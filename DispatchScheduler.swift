/*
 * DispatchScheduler.swift
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

public class DispatchScheduler: Scheduler {
    
    private let dispatcher: Dispatcher
    private let dispatchTable: DispatchTable
    
    public init(dispatcher: Dispatcher, dispatchTable: DispatchTable) {
        self.dispatcher = dispatcher
        self.dispatchTable = dispatchTable
    }
    
    public func run() {
        var startRunTime = microseconds()   // When did we start?
        var i: UInt = 0                     // The index of the current machine.
        while(false == self.dispatchTable.empty()) {
            let d: Dispatchable = self.dispatchTable.get()
            // Reset timers when we execute all items in the dispatch table.
            if (self.dispatchTable.count() == i++) {
                i = 1
                startRunTime = microseconds()
            }
            // Execute the machine if it has not finished.
            if (false == d.item.fsm.hasFinished()) {
                self.runTask(d, startRunTime: startRunTime)
                self.dispatchTable.advance()
                continue
            }
            // Remove the machine from the dispatch table if it has finished.
            self.dispatchTable.remove()
            if (true == self.dispatchTable.empty()) {
                return
            }
            self.dispatchTable.advance()
        }
    }
    
    private func runTask(d: Dispatchable, startRunTime: UInt) {
        let taskStartTime: UInt = d.startTime
        let elapsedTime = microseconds() - startRunTime
        // Only sleep if we have not reached the start time.
        if (taskStartTime > elapsedTime) {
            print("\(d.item.name) sleepTime: \(taskStartTime - elapsedTime)")
            microsleep(taskStartTime - elapsedTime)
        }
        self.dispatcher.run(d)
        return
    }
    
}

/*
 * MachineRunner.swift
 * swiftfsm
 *
 * Created by Callum McColl on 25/10/2015.
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

import Swift_FSM

public class MachineRunner: CommandQuerier {
    
    private var _currentlyRunning: Bool = false
    private let executer: ThreadExecuter
    private let machine: Machine
    private let runSem: UnsafeMutablePointer<sem_t>
    
    public private(set) var averageRunTime: UInt = 0
    
    public private(set) var currentlyRunning: Bool {
        get {
            sem_wait(self.runSem)
            let temp: Bool = self._currentlyRunning
            sem_post(self.runSem)
            return temp
        } set {
            sem_wait(self.runSem)
            self._currentlyRunning = newValue
            sem_post(self.runSem)
        }
    }
    
    public private(set) var lastRunTime: UInt = 0
    public private(set) var totalRunTime: UInt = 0
    public private(set) var totalTimesRun: UInt = 0
    
    public init(machine: Machine, executer: ThreadExecuter) {
        self.executer = executer
        self.machine = machine
        self.runSem = sem_open(
            "machine_runner_runSem_" + machine.name,
            O_CREAT,
            0,
            1
        )
    }
    
    private func _run() {
        let timestamp: Int = microseconds()
        self.machine.machine.next()
        self.lastRunTime = UInt(microseconds() - timestamp)
        self.totalRunTime = self.totalRunTime + self.lastRunTime
        self.averageRunTime = self.totalRunTime / (++self.totalTimesRun)
        self.currentlyRunning = false
    }
    
    public func run() {
        self.currentlyRunning = true
        self.executer.execute(self._run)
    }
    
    public func run(callback: () -> Void) {
        self.currentlyRunning = true
        self.executer.execute({
            self._run()
            callback()
        })
    }
    
    deinit {
        sem_close(self.runSem)
    }
    
}
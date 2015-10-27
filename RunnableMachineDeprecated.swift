/*
 * RunnableMachine.swift
 * swiftfsm
 *
 * Created by Callum McColl on 26/10/2015.
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

/**
 *  Provides a simple interface to access common information from a
 *  MachineRunner.
 *
 *  If directly using a MachineRunner it becomes tedious to access information
 *  related to a Machine.  This class provides that information at the top level
 *  so that you don't have to use the MachineRunner.machine class property.
 *  This therefore allows you to check whether the Machine is finished by
 *  performing `RunnableMachine.machine.isFinished()` instead of performing
 *  `MachineRunner.machine.machine.isFinished()` thus giving you direct access
 *  to the FiniteStateMachine instance.
 *
 *  This class also provides top level access to the other Machine class
 *  properties by allowing you to access them directly, eg: by performing
 *  `RunnableMachine.name` instead of `MachineRunner.machine.name`.
 */
public class RunnableMachine: CommandQuerier, Machine {
    
    private let runner: MachineRunner
    
    public var averageExecutionTime: UInt {
        return self.runner.averageExecutionTime
    }
    
    public var bestCaseExecutionTime: UInt {
        return self.runner.bestCaseExecutionTime
    }
    
    public var currentlyRunning: Bool {
        return self.runner.currentlyRunning
    }
    
    public var lastExecutionTime: UInt {
        return self.runner.lastExecutionTime
    }
    
    public var machine: FiniteStateMachine {
        get {
            return self.runner.machine.machine
        } set {
            self.runner.machine.machine = newValue
        }
    }
    
    public var name: String {
        return self.runner.machine.name
    }
    
    public var totalExecutionTime: UInt {
        return self.runner.totalExecutionTime
    }
    
    public var totalExecutions: UInt {
        return self.runner.totalExecutions
    }
    
    public var worstCaseExecutionTime: UInt {
        return self.runner.worstCaseExecutionTime
    }
    
    public init(runner: MachineRunner) {
        self.runner = runner
    }
    
    public func execute() {
        return self.runner.execute()
    }
    
    public func execute(callback: () -> Void) {
        return self.runner.execute(callback)
    }
    
    public func stop() {
        return self.runner.stop()
    }
    
}

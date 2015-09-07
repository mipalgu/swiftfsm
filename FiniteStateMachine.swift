/*
 * FiniteStateMachine.swift
 * swiftfsm
 *
 * Created by Callum McColl on 12/08/2015.
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
 *  A common interface for the operations that finite state machines can
 *  execute.
 */
public protocol _FiniteStateMachine {
    
    var currentState: State { get set }
    var initialState: State { get }
    var ringlet: Ringlet { get }
    var suspendedState: State? { get set }
    
}

public extension _FiniteStateMachine where Self: Exitable, Self: Suspendable {
    
    public mutating func exit() -> Void {
        self.resume()
        self.currentState = EmptyState(name: "_exit")
    }
    
    public func hasFinished() -> Bool {
        return !self.isSuspended() && 0 == self.currentState.transitions.count
    }
    
}

public extension _FiniteStateMachine where Self: Suspendable {
    
    public func isSuspended() -> Bool {
        return self.suspendedState != nil
    }
    
    public mutating func resume() -> Void {
        if (false == self.isSuspended()) {
            return
        }
        self.currentState = self.suspendedState!
        self.suspendedState = nil
    }
    
    public mutating func suspend() -> Void {
        self.suspendedState = self.currentState
        self.currentState = EmptyState(name: "_suspend")
    }
    
}
public extension _FiniteStateMachine where Self: Restartable, Self: Suspendable {
    
    public mutating func restart() -> Void {
        self.resume()
        self.currentState = self.initialState
    }
    
}

public extension _FiniteStateMachine where Self: StateExecuter, Self: Suspendable {
    
    public mutating func next() {
        if (self.isSuspended()) {
            return
        }
        self.currentState = self.ringlet.execute(self.currentState)
    }
    
}

public protocol FiniteStateMachine:
    _FiniteStateMachine,
    Exitable,
    Restartable,
    StateExecuter,
    Suspendable
{}
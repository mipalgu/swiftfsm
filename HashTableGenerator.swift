/*
 * HashTableGenerator.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 30/06/2016.
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

import FSM

public class HashTableGenerator<
    Ma: Machine,
    G: KripkeStateGeneratorType
>: SteppingKripkeStructureGenerator {

    public typealias M = Ma

    private var cycleLength: Int = 0

    private var cyclePos: Int = 0

    private var cycleState: KripkeState!

    private let fsm: FiniteStateMachine

    private var inCycle: Bool = false

    public private(set) var isFinished: Bool = false

    private let generator: G

    private var lastState: KripkeState!

    public let machine: M

    private var pos: Int = 0

    var states: [String: (Int, KripkeState)] = [:]

    public init(fsm: FiniteStateMachine, machine: M, generator: G) {
        self.fsm = fsm
        self.machine = machine
        self.generator = generator
    }

    public func next() -> KripkeState  {
        if (self.lastState == nil) {
            self.lastState = self.generateNextState()
            return self.lastState
        }
        if (true == isFinished) {
            return self.lastState
        } 
        let state: KripkeState = self.generateNextState()
        self.lastState.target = state
        self.pos += 1
        if (true == self.inCycle) {
            if (self.cyclePos >= self.cycleLength) {
                self.isFinished = true
                return state
            }
            self.handleCycle(state: state)
        }
        if (false == self.inCycle && self.states[state.description] != nil) {
            self.inCycle = true
            self.cycleState = self.states[state.description]!.1
            self.cyclePos = 0
            self.cycleLength = self.pos - self.states[state.description]!.0
        }
        if (nil == self.states[state.description]) {
            self.states[state.description] = (pos, state)
        } else {
            self.states[state.description] = (pos, state)
        }
        self.isFinished = self.fsm.hasFinished && self.lastState == state
        self.lastState = state
        return state
    }

    private func handleCycle(state: KripkeState) {
        self.cycleState = self.cycleState.target!
        self.inCycle = state == self.cycleState
        self.cyclePos += 1
        if (false == self.inCycle) {
            self.cycleLength = 0
        }
    }

    private func generateNextState() -> KripkeState {
        return self.generator.generate(fsm: self.fsm, machine: self.machine)
    }
}

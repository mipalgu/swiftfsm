/*
 * TeleportingTurtleGenerator.swift
 * swiftfsm
 *
 * Created by Callum McColl on 28/11/2015.
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

import FSM

public class TeleportingTurtleGenerator: FSMKripkeStateGenerator {
    
    private let extractor: StatePropertyExtractor
    
    public init(extractor: StatePropertyExtractor) {
        self.extractor = extractor
    }
    
    /**
     *  Generate a kripke structure from the initial state of the finite state
     *  machine.
     *
     *  This uses Brents Teleporting Turtle algorithm to detect cycles within
     *  the Kripke Structure.  Once the algorithm detects that there is a cycle
     *  it starts at the inital state and loops until it finds the first
     *  occurence of the cycle and from this you would normally trim the
     *  remaining states off the end since they are just cyclying.  This
     *  trimming does not happen so you may end up with a few states that end up
     *  doing the same thing.
     *
     *  In other words the algorithm detects if a cycle has happend and stops
     *  generating the structure, but, it does not bother to remove the cyclic
     *  states from the end of the structure.
     */
    public func generateFromFSM(var fsm: FiniteStateMachine) -> KripkeState {
        var turtle: KripkeState = self.convertToKripkeState(fsm.currentState)
        fsm.next()
        var rabbit: KripkeState = self.convertToKripkeState(fsm.currentState)
        turtle.target = rabbit
        var power: Int = 1
        var length: Int = 1
        let initialState: KripkeState = turtle
        while(turtle != rabbit) {
            if (power == length) {
                turtle = rabbit
                power *= 2
                length = 0
            }
            fsm.next()
            let temp: KripkeState = self.convertToKripkeState(fsm.currentState)
            rabbit.target = temp
            rabbit = temp
            length++
            if (true == fsm.hasFinished()) {
                break
            }
        }
        return initialState
    }
    
    private func convertToKripkeState(state: State) -> KripkeState {
        return KripkeState(
            state: state,
            properties: self.extractor.extract(state)
        )
    }
    
}

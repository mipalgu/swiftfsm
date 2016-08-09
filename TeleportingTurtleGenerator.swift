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

public class TeleportingTurtleGenerator<
    Generator: KripkeStateGeneratorType
>: SteppingKripkeStructureGenerator {

    private var fsm: AnyScheduleableFiniteStateMachine

    private let generator: Generator

    public let machine: Machine

    public private(set) var isFinished: Bool

    private var turtle: KripkeState!
    private var rabbit: KripkeState!
    private var lastState: KripkeState!
    private var power: Int                  // How much distance the turtle and rabbit should have before bringing them together again.
    private var length: Int                 // The current distance between the turtle and rabbit.
    private var inCycle: Bool               // Are we checking a cycle?
    private var cyclePos: Int               // The current position in the cycle
    private var cycleState: KripkeState!    // The current state that is being checked in the cycle
    
    public init(
        fsm: AnyScheduleableFiniteStateMachine,
        machine: Machine,
        generator: Generator
    ) {
        self.fsm = fsm
        self.machine = machine
        self.generator = generator
        self.isFinished = false 
        self.power = 1
        self.length = 1
        self.inCycle = false
        self.cyclePos = 0
        self.turtle = nil
    }

    /**
     *  Generate a kripke structure from the initial state of the finite state
     *  machine.
     *
     *  This uses Brents Teleporting Turtle algorithm to detect cycles within
     *  the Kripke Structure.  Once the algorithm detects a potential cycle it
     *  checks every newly generated state with those that it has already seen
     *  to make sure that it is equal to the corresponding state in the cycle.
     *  If all newly generated states are equal to their corresponding states 
     *  within the cycle for the entire cycle then a cycle has been detected and
     *  the generation of the kripke state is stopped and the inital state of 
     *  the structure is returned.  Normally the algorithm would trim the cyclic
     *  states off the end but this does not happen so you may end up with a 
     *  few states on the end that are doing the same thing.
     *
     *  To summarize the algorithm detects if a cycle has happend and stops
     *  generating the structure, but, it does not bother to remove the cyclic
     *  states from the end of the structure.
     */
    public func next() -> [KripkeState] {
        // Have we started yet?
        if (nil == self.turtle) {
            // No - finish setup.
            let states: [KripkeState] = self.generateNextStates()
            return states.flatMap {
                if ($0 == self.turtle) {
                    return nil
                }
                self.turtle = $0
                self.rabbit = self.turtle
                self.lastState = self.turtle
                self.cycleState = self.turtle
                return $0
            }
        }
        // Don't bother generating any further if we have finished.
        if (true == self.fsm.hasFinished) {
            self.isFinished = true
        }
        if (true == self.isFinished) {
            return []
        }
        let states: [KripkeState] = self.generateNextStates()
        return states.flatMap {
            if (true == self.isFinished) {
                return nil
            }
            let temp: KripkeState = $0
            // Ignore repeating states.
            if (temp == self.lastState) {
                return nil
            }
            // Teleport the turtle if we are not in a cycle.
            if (false == self.inCycle) {
                // 'Teleport' the turtle to the rabbit when necessary.
                self.tp()
            }
            // Update the rabbit with the new state and remember the last state.
            self.rabbit.target = temp
            self.lastState = self.rabbit
            self.rabbit = temp
            // Have we found a new cycle?
            if (false == self.inCycle && self.rabbit == self.turtle) {
                // Start checking the cycle and reset the cycle variables
                self.inCycle = true
                self.cycleState = self.turtle
                self.cyclePos = 0
            }
            // Are we checking a cycle?
            if (true == inCycle) {
                // Have we reached the end of the cycle?
                if (self.cyclePos > self.length) {
                    self.isFinished = true
                    return self.rabbit
                }
                // Is there a state that doesn't match the cycle?
                self.inCycle = self.rabbit == self.cycleState
                // Check the next state in the cycle
                self.cycleState = self.cycleState.target!
                self.cyclePos += 1
            }
            self.isFinished = 
                self.fsm.hasFinished && 
                self.rabbit == self.lastState
            return self.rabbit
        }
    }

    private func generateNextStates() -> [KripkeState] {
        return self.generator.generate(fsm: self.fsm, machine: self.machine)
    }

    private func tp() {
        let temp: Int = self.length
        self.length += 1
        if (self.power != temp) {
            return
        }
        self.turtle = self.rabbit
        self.power *= 2
        self.length = 1
    }

}

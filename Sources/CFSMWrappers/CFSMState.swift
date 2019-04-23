/*
 * CFSMState.swift
 * swiftfsm
 *
 * Created by Bren Moushall on 22/08/2017.
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
import KripkeStructure
import swift_CLReflect
import swiftfsm

/**
 * An implementation of MiPalState that allows delegation of actions to an underlying CLReflect metamachine.
 */
open class CFSMState: MiPalState
{
    /**
     * The underlying CLReflect metamachine.
     */
    fileprivate let metaMachine: refl_metaMachine

    /**
     * This state's number as represented in the CLReflect metamachine.
     */
    public let stateNumber: Int

    /**
     * An array of transitions that this state may use to move to another state.
     */
    //public override let transitions: [Transition<CFSMState, CFSMState>]

    /**
     *  Create a new `CFSMState`.
     *
     *  - Parameter name: The name of the state.
     *  - Parameter transitions: All transitions to other states that this state can use.
     *  - Parameter metaMachine: The underlying CLReflect metamachine.
     *  - Parameter stateNumber: The state's number as represented in the CLReflect metamachine.
     */
    public init(_ name: String, transitions: [_TransitionType] = [], metaMachine: refl_metaMachine, stateNumber: Int) {
        self.metaMachine = metaMachine
        self.stateNumber = stateNumber
        super.init(name, transitions: transitions)
    }

    /**
     *  Delegates the execution of the onEntry action to the CLReflect metamachine.
     */
    open override func onEntry() {
       refl_invokeOnEntry(self.metaMachine, UInt32(self.stateNumber), nil)
    }

    /**
     *  Delegates the execution of the main (internal) action to the CLReflect metamachine.
     */
    open override func main() { 
        refl_invokeInternal(self.metaMachine, UInt32(self.stateNumber), nil)
    }

    /**
     *  Delegates the execution of the onExit action to the CLReflect metamachine.
     */
    open override func onExit() {
        refl_invokeOnExit(self.metaMachine, UInt32(self.stateNumber), nil)
    }

    /**
     * Returns the result of CLReflect's evaluation of one of this state's transitions
     */
    open func evaluateTransition(transitionNumber: Int) -> Bool {
        let res = refl_evaluateTransition(self.metaMachine, UInt32(self.stateNumber), UInt32(transitionNumber), nil)
        return res == 1 ? true : false
    }


    /**
     *  Create a copy of `self`.
     *
     *  - Warning: Child classes should override this method.  If they do not
     *  then the application will crash when trying to generate
     *  `KripkeStructures`.
     */
    open override func clone() -> Self {
        return self
    }

}

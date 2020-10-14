/*
 * FSMLocater.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 22/12/2018.
 * Copyright © 2018 Callum McColl. All rights reserved.
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
 *  This protocol provides a common interface for machines to be able to
 *  interact with instances of other machines which they depend on.
 *
 *  An example is machines that depend on other submachines. Through the use of
 *  this protocol, machines are able to fetch instances of other machine which
 *  can be used to perform some of the general operations provided by swiftfsm.
 *  These include suspension, resumption, restarting fsms and forcing fsms
 *  to finish.
 *
 */
public protocol FSMLocator: class {

    /**
     *  Fetch an FSM from its associated unique identifier.
     *
     *  - Parameter id: The id associated with an instance of
     *  `AnyScheduleableFiniteStateMachine`. How this id is fetched or assigned
     *  is beyond the scope of this protocol.
     *
     *  - Returns: The `AnyControllableFiniteStateMachine` associated with the
     *  provided identifier.
     *
     *  - Attention: This function assumes that the id specified is already
     *  associated with an FSM. If this is not the case then this function
     *  will cause a fatal error.
     *
     *  - Complexity: O(1)
     */
    func fsm(fromID id: FSM_ID) -> AnyControllableFiniteStateMachine

    /**
     *  Fetch the unique identifer associated with an FSM.
     *
     *  - Parameter name: The name of the FSM.
     *
     *  - Returns: The id of the FSM.
     *
     *  - Attention: Attempting to fetch the id using an invalid name will
     *  result in a new id being associated with `name`. Any further call to
     *  this function with the same value for `name` will therefore return
     *  this newly generated unique identifier.
     *
     *  - Attention: This function mandates that FSM's may only fetch id's
     *  of other FSM's which they depend on. This means that they are unable to
     *  fetch id's of arbitrary machines which do not exist within their
     *  hierarchy.
     *
     *  - Complexity: O(length(name))
     */
    func id(of name: String) -> FSM_ID

}

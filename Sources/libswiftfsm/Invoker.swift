/*
 * Invoker.swift 
 * FSM 
 *
 * Created by Callum McColl on 15/08/2018.
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

import FSM
import Utilities

public protocol Invoker {

    /**
     *  'Call' a parameterised machine.
     *
     *  This function has the same semantics has normal function calling in
     *  programming languages. The execution passes to the invokee where the
     *  invoker does not execute until the invokee has finished and has returned
     *  from the call.
     *
     *  - Parameter id: The unique identifier of the parameterised FSM which
     *  we are calling.
     *
     *  - Parameter parameters: A list of key-value pairs which represent the
     *  parameters of the call. The key represents the label of the parameter
     *  and the value is the actual value that will be assigned to that
     *  parameter.
     *
     *  - Parameter caller: The id of the caller FSM.
     *
     *  - Returns: A `Promise` representing the status of the invocation;
     *  containing the returned value once the invocation has been complete.
     */
    func call<R>(_ id: FSM_ID, withParameters parameters: [String: Any], caller: FSM_ID) -> Promise<R>

    /**
     *  'Call' yourself recursively.
     *
     *  This function has the equivalent to calling
     *  `call(_:withParameters:caller:)` where `id` and `caller` have the same
     *  value.
     *
     *  - Parameter id: The unique identifier of the parameterised FSM which
     *  is being recursively invoked.
     *
     *  - Parameter parameters: A list of key-value pairs which represent the
     *  parameters of the call. The key represents the label of the parameter
     *  and the value is the actual value that will be assigned to that
     *  parameter.
     *
     *  - Returns: A `Promise` representing the status of the invocation;
     *  containing the returned value once the invocation has been complete.
     */
    func callSelf<R>(_: FSM_ID, withParameters: [String: Any]) -> Promise<R>

    /**
     *  'Invoke' a parameterised machine.
     *
     *  This function has the semantics of a parallel process. In this way,
     *  the invoker keeps running while the invokee is executing.
     *
     *  - Parameter id: The unique identifier of the parameterised FSM which
     *  we are calling.
     *
     *  - Parameter parameters: A list of key-value pairs which represent the
     *  parameters of the call. The key represents the label of the parameter
     *  and the value is the actual value that will be assigned to that
     *  parameter.
     *
     *  - Returns: A `Promise` representing the status of the invocation;
     *  containing the returned value once the invocation has been complete.
     */
    func invoke<R>(_: FSM_ID, withParameters: [String: Any], caller: FSM_ID) -> Promise<R>

}

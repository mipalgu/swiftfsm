/*
 * KripkeVariablesModifier.swift 
 * FSM 
 *
 * Created by Callum McColl on 05/10/2016.
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

/**
 *  Allows conforming types to manipulate the values of variables that are used
 *  in `KripkeStructures`.
 */
public protocol KripkeVariablesModifier {

    /**
     * Allows conforming types to create computed variables that are only seen
     * by the model generation.  This is especially useful when representing
     * conditions that influence the execution.  For example: when executing
     * a state using the `MiPalRinglet`, the onEntry action is not executed
     * if the previous state equals the current state.  In order to minimise
     * combinatorial state explosion, it is worth ignoring the previous state,
     * and simply using a 'shouldExecuteOnEntry' computedVar instead.  This
     * means that there are only 2 possible combinations, either
     * 'shouldExecuteOnEntry' is false, or 'shouldExecuteOnEntry' is true,
     * rather than the 'n' possible situations where the previous state could
     * be set to some arbitrary value.
     */
    var computedVars: [String: Any] { get }

    /**
     *  A dictionary where the keys represent the label of each variables and
     *  the values represent a function which takes a current value and
     *  manipulates it and returns the new value, which the `KripkeStructure`
     *  should use.
     */
    var manipulators: [String: (Any) -> Any] { get }

    /**
     *  A dictionary where the keys represent the labels of each variable and
     *  the values represent all possible valid values of the variables.
     */
    var validVars: [String: [Any]] { get }

}

extension KripkeVariablesModifier {

    public var computedVars: [String: Any] { return [:] }

    public var manipulators: [String: (Any) -> Any] { return [:] }

    public var validVars: [String: [Any]] { return [:] }

    public var spinVars: [String: [Any]] { return [:] }

}

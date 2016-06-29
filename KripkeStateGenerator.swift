/*
 * KripkeStateGenerator.swift 
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

public class KripkeStateGenerator: KripkeStateGeneratorType {

    private let fsmExtractor: FSMPropertyExtractor
    
    private let globalsExtractor: GlobalPropertyExtractor

    private let stateExtractor: StatePropertyExtractor

    public init(
        globalsExtractor: GlobalPropertyExtractor,
        fsmExtractor: FSMPropertyExtractor,
        stateExtractor: StatePropertyExtractor
    ) {
        self.globalsExtractor = globalsExtractor
        self.fsmExtractor = fsmExtractor
        self.stateExtractor = stateExtractor
    }

    public func generate<M: Machine>(
        fsm: FiniteStateMachine,
        machine: M
    ) -> KripkeState {
        var fsm = fsm
        let s: State = fsm.currentState
        // Extract the fsm and state properties.
        let beforeProperties: [String: KripkeStateProperty] = 
            self.stateExtractor.extract(state: s)
        let beforeFsmProperties: [String: KripkeStateProperty] = 
            self.fsmExtractor.extract(vars: fsm.vars)
        // Execute the state.
        fsm.next()
        // Extract the fsm and state properties again.
        let afterProperties: [String: KripkeStateProperty] =
            self.stateExtractor.extract(state: s)
        let afterFsmProperties: [String: KripkeStateProperty] =
            self.fsmExtractor.extract(vars: fsm.vars)
        // Get global properties
        let globalProperties: (
            before: [String: KripkeStateProperty],
            after: [String: KripkeStateProperty]
        ) = self.globalsExtractor.extract(ringlet: fsm.ringlet)
        // Create Before and After Property Lists
        let before: KripkeStatePropertyList = KripkeStatePropertyList(
            stateProperties: beforeProperties,
            fsmProperties: beforeFsmProperties,
            globalProperties: globalProperties.before
        )
        let after: KripkeStatePropertyList = KripkeStatePropertyList(
            stateProperties: afterProperties,
            fsmProperties: afterFsmProperties,
            globalProperties: globalProperties.after
        )
        // Create the Kripke State
        return KripkeState(
            state: s,
            fsm: fsm,
            machine: machine,
            beforeProperties: before,
            afterProperties: after
        )
    }

}

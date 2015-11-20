/*
 * FSMKripkeStructureGenerator.swift
 * swiftfsm
 *
 * Created by Callum McColl on 11/11/2015.
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

public class FSMKripkeStructureGenerator: KripkeStructureGenerator {
    
    private let extractor: StatePropertyExtractor
    
    private let fsm: FiniteStateMachine
    
    public init(extractor: StatePropertyExtractor, fsm: FiniteStateMachine) {
        self.extractor = extractor
        self.fsm = fsm
    }
    
    public func generate() -> KripkeStructureType {
        // Generate the structure.
        return KripkeStructure(
            initialState: self.generateFromFSM(fsm),
            fsm: self.fsm
        )
    }
    
    private func convertToKripkeState(state: State) -> KripkeState {
        return KripkeState(properties: self.extractor.extract(state))
    }
    
    /*
     *  Generate a kripke structure from the initial state of the finite state
     *  machine.
     */
    private func generateFromFSM(fsm: FiniteStateMachine) -> KripkeState {
        var path: [State] = []
        while(false == fsm.hasFinished()) {
            let temp: (path: [State], length: Int) = self.buildStatePath(fsm)
            path.appendContentsOf(temp.path)
            if (true == isCycle(temp.path, length: temp.length)) {
                break
            }
        }
        return self.buildKripkeStructure(path)
    }
    
    private func buildStatePath(var fsm: FiniteStateMachine) -> ([State], Int) {
        var tortoise: State = fsm.currentState
        fsm.next()
        var hare: State = fsm.currentState
        var history: [State] = [tortoise, hare]
        var power: Int = 1
        var length: Int = 1
        while (tortoise != hare && false == fsm.hasFinished()) {
            if (power == length) {
                tortoise = hare
                power *= 2
                length = 0
            }
            fsm.next()
            hare = fsm.currentState
            length++
            history.append(hare)
        }
        return (history, length)
    }
    
    private func isCycle(history: [State], length: Int) -> Bool {
        var tortoise: State = history[0]
        var hare: State = history[length]
        var ti: Int = 0
        var hi: Int = length
        while (tortoise != hare) {
            tortoise = history[++ti]
            hare = history[++hi]
        }
        var i: Int = 0
        while (tortoise == hare && i++ < length && hi + 1 < history.count) {
            tortoise = history[++ti]
            hare = history[++hi]
        }
        return tortoise == hare
    }
    
    private func buildKripkeStructure(path: [State]) -> KripkeState {
        if (0 == path.count) {
            return self.convertToKripkeState(EmptyState(name: "_empty"))
        }
        let initialState: KripkeState = self.convertToKripkeState(path[0])
        var last: KripkeState = initialState
        for i in 1 ... path.count - 2 {
            let temp: KripkeState = self.convertToKripkeState(path[i])
            last.target = temp
            temp.source = last
            last = temp
        }
        return initialState
    }
    
}

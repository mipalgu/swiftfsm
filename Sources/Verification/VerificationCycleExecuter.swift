/*
 * VerificationCycleExecuter.swift
 * Verification
 *
 * Created by Callum McColl on 10/9/18.
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
import KripkeStructure
import MachineStructure
import swiftfsm

public final class VerificationCycleExecuter<StateGenerator: KripkeStateGeneratorProtocol> {
    
    fileprivate let stateGenerator: StateGenerator
    
    public init(stateGenerator: StateGenerator) {
        self.stateGenerator = stateGenerator
    }
    
    public func execute(
        tokens: [[VerificationToken]],
        executing: Int,
        withExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andLastState last: KripkeState?
    ) -> [KripkeState] {
        var last = last
        var offset: Int = 0
        //swiftlint:disable:next line_length
        return tokens[executing].flatMap { (token: VerificationToken) -> [KripkeState] in
            if true == token.fsm.hasFinished {
                offset += 1
                return []
            }
            let state = token.fsm.currentState.name
            let preWorld = self.createWorld(
                fromExternals: externals,
                andTokens: tokens,
                andLastState: last,
                andExecuting: executing,
                andExecutingToken: offset,
                withState: state,
                appendingToPC: "R"
            )
            let preState = self.stateGenerator.generateKripkeState(
                fromFSM: token.fsm.clone(),
                withinMachine: token.machine,
                withLastState: last,
                addingProperties: preWorld
            )
            token.fsm.next()
            let postWorld = self.createWorld(
                fromExternals: externals,
                andTokens: tokens,
                andLastState: preState,
                andExecuting: executing,
                andExecutingToken: offset,
                withState: state,
                appendingToPC: "W"
            )
            let postState = self.stateGenerator.generateKripkeState(
                fromFSM: token.fsm.clone(),
                withinMachine: token.machine,
                withLastState: preState,
                addingProperties: postWorld
            )
            last = postState
            offset += 1
            return [preState, postState]
        }
    }
    
    //swiftlint:disable:next function_parameter_count
    fileprivate func createWorld(
        fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andTokens tokens: [[VerificationToken]],
        andLastState lastState: KripkeState?,
        andExecuting executing: Int,
        andExecutingToken token: Int,
        withState state: String,
        appendingToPC str: String
    ) -> KripkeStatePropertyList {
        let externalVariables = self.convert(externals: externals)
        let varPs = self.convert(
            tokens: tokens,
            executing: executing,
            executingToken: token,
            withState: state,
            appendingToPC: str
        )
        return (lastState?.properties ?? [:]) <| varPs <| externalVariables
    }
    
    private func convert(externals: [(AnySnapshotController, KripkeStatePropertyList)]) -> KripkeStatePropertyList {
        var props: KripkeStatePropertyList = [:]
        var values: [String: Any] = [:]
        externals.forEach {
            props[$0.0.name] = KripkeStateProperty(type: .Compound($0.1), value: $0.0.val)
            values[$0.0.name] = $0.0.val
        }
        return [
            "externalVariables": KripkeStateProperty(
                type: .Compound(props),
                value: values
            )
        ]
    }
    
    private func convert(
        tokens: [[VerificationToken]],
        executing: Int,
        executingToken token: Int,
        withState state: String,
        appendingToPC str: String
    ) -> KripkeStatePropertyList {
        var varPs: KripkeStatePropertyList = [:]
        tokens.forEach {
            $0.forEach {
                varPs["\($0.machine.name).\($0.fsm.name)"] = KripkeStateProperty(
                    type: .Compound($0.fsm.currentRecord),
                    value: $0.fsm
                )
            }
        }
        varPs["pc"] = KripkeStateProperty(
            type: .String,
            value: self.createPC(ofToken: tokens[executing][token], withState: state, appending: str)
        )
        return varPs
    }
    
    fileprivate func createPC(
        ofToken token: VerificationToken,
        withState state: String,
        appending str: String
    ) -> String {
        return "\(token.machine.name).\(token.fsm.name).\(state).\(str)"
    }
    
}

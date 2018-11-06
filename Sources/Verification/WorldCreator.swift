/*
 * WorldCreator.swift
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
import ModelChecking
import swiftfsm

public final class WorldCreator {
    
    fileprivate let recorder = MirrorKripkePropertiesRecorder()
    
    public init() {}
    
    //swiftlint:disable:next function_parameter_count
    public func createWorld(
        fromExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andTokens tokens: [[VerificationToken]],
        andLastState lastState: KripkeState?,
        andExecuting executing: Int,
        andExecutingToken token: Int,
        withState state: String,
        worldType: WorldType
    ) -> KripkeStatePropertyList {
        let externalVariables = self.convert(externals: externals, withLastState: lastState)
        let str: String
        switch worldType {
        case .beforeExecution:
            str = "R"
        case .afterExecution:
            str = "W"
        }
        let varPs = self.convert(
            tokens: tokens,
            executing: executing,
            executingToken: token,
            withState: state,
            appendingToPC: str
        )
        var total: [String: KripkeStateProperty] = lastState?.properties.properties ?? [:]
        for (key, val) in varPs.properties {
            total[key] = val
        }
        for (key, val) in externalVariables.properties {
            total[key] = val
        }
        return KripkeStatePropertyList(total)
        //return (lastState?.properties ?? [:]) <| varPs <| externalVariables
    }
    
    fileprivate func fetchLastExternals(fromLastState lastState: KripkeState?) -> KripkeStatePropertyList {
        guard let externalsProperty = lastState?.properties.properties["externalVariables"] else {
            return [:]
        }
        switch externalsProperty.type {
        case .Compound(let props):
            return props
        default:
            return [:]
        }
    }
    
    private func convert(externals: [(AnySnapshotController, KripkeStatePropertyList)], withLastState lastState: KripkeState?) -> KripkeStatePropertyList {
        let lastExternals = self.fetchLastExternals(fromLastState: lastState)
        var props: KripkeStatePropertyList = [:]
        var values: [String: Any] = [:]
        externals.forEach {
            props[$0.0.name] = KripkeStateProperty(type: .Compound($0.1), value: $0.0.val)
            values[$0.0.name] = $0.0.val
        }
        return [
            "externalVariables": KripkeStateProperty(
                type: .Compound(lastExternals.merged(props)),
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
                varPs[$0.fsm.name] = KripkeStateProperty(
                    type: .Compound(self.recorder.takeRecord(of: $0.fsm.base)),
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
        return "\(token.fsm.name).\(state).\(str)"
    }
    
}

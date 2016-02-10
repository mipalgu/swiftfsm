/*
 * NuSMVKripkeStructureView.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 12/01/2016.
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

public class NuSMVKripkeStructureView<T: OutputStreamType>:
    KripkeStructureView
{

    private var data: Data!

    private var stream: T 

    public init(stream: T) {
        self.stream = stream
    }

    public func make(structure: KripkeStructureType) {
        if (true == structure.states.isEmpty) {
            return
        }
        self.data = Data(machine: structure.machine, states: structure.states)
        var str: String = "MODULE main\n\n"
        self.createTrans()
        self.createVars()
        str += self.data.vars + self.data.trans
        print(str, terminator: "", toStream: &self.stream)
    }

    private func createTrans() {
        var lastState: KripkeState = self.data.states[0]
        var lastPcName :String = getNextName(lastState)
        self.data.states.removeFirst()
        self.data.states.forEach {
            let pcName: String = getNextName($0)
            self.data.trans += getTrans(lastPcName, state: lastState)
            self.data.trans += getChanges(pcName, state: $0)
            lastState = $0
            lastPcName = pcName
        }
        self.data.trans += "esac\n"
    }

    private func createVars() {
        self.data.properties.map {
            self.data.vars += "\($0) : {"
            var pre: Bool = false
            $1.forEach {
                self.data.vars += (true == pre ? ",\n" : "\n") + "\($0.value)"
                pre = true
            }
            self.data.vars += "\n};\n\n"
        }
        self.data.vars += "pc : {\n"
        self.data.pc.forEach { self.data.vars += $0 + "\n" }
        self.data.vars += "};\n\n"
        self.data.vars += "INIT\n"
        self.data.vars += "pc=\(self.data.pc[0])\n"
    }

    private func getTrans(
        pcName: String,
        state: KripkeState,
        prep: String = "",
        app: String = "",
        start: String = "",
        terminator: String = ":",
        addToProperties: Bool = true
    ) -> String {
        var str: String = start 
        var pre: Bool = false
        state.fsmProperties.forEach {
            str += generate(
                "\(prep)\(state.fsm.name)$$\($0)\(app)",
                p: $1,
                pre: &pre,
                addToProperties: addToProperties
            )
        }
        state.properties.forEach {
            if ($0 == "name") {
                return
            }
            str += generate(
                "\(prep)\(state.fsm.name)$$\(state.state.name)$$\($0)\(app)",
                p: $1,
                pre: &pre,
                addToProperties: addToProperties
            )
        }
        state.globalProperties.forEach {
            str += generate(
                "\(prep)globals$$\($0)\(app)",
                p: $1,pre: &pre,
                addToProperties: addToProperties
            )
        }
        str += 
            (true == pre ? " & " : "") + "\(prep)pc\(app)=\(pcName)\(terminator)\n"
        return str
    }

    private func getChanges(pcName: String, state: KripkeState) -> String {
        return self.getTrans(
            pcName,
            state: state,
            prep: "next(",
            app: ")",
            start: "    ",
            terminator: ";",
            addToProperties: false
        ) 
    }

    private func getNextName(state: KripkeState) -> String {
        var name: String = 
            "\(self.data.machine.name)$$\(state.fsm.name)$$\(state.state.name)"
        if (nil == self.data.ringlets[name]) {
            self.data.ringlets[name] = -1
        }
        self.data.ringlets[name]! += 1
        name += "$$R\(self.data.ringlets[name]!)"
        self.data.pc.append(name)
        return name
    }

    private func generate(
        name: String,
        p: KripkeStateProperty,
        inout pre: Bool,
        addToProperties: Bool
    ) -> String {
        if (p.type == .Some) {
            return ""
        }
        if (true == addToProperties) {
            self.addToProperties(name, p: p)
        }
        var str: String = ""
        if (true == pre) {
           str += " & " 
        }
        str += "\(name)=\(p.value)"
        pre = true
        return str
    }

    private func addToProperties(name: String, p: KripkeStateProperty) {
        if (nil == self.data.properties[name]) {
            self.data.properties[name] = []
        }
        if (false == self.data.properties[name]!.contains({ $0 == p })) {
            self.data.properties[name]!.append(p)
        }
    }

}

private class Data {

    public var properties: [String: [KripkeStateProperty]] = [:]
    public var states: [KripkeState]
    public let machine: Machine
    public var str: String = "MODULE main\n\n"
    public var vars: String = "VAR\n\n"
    public var trans: String = "TRANS\ncase\n"
    public var ringlets: [String: Int] = [:]
    public var pc: [String] = []

    public init(machine: Machine, states: [KripkeState]) {
        self.machine = machine
        self.states = states
    }

}

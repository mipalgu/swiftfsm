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

public class NuSMVKripkeStructureView: KripkeStructureView {

    private let delimiter: String

    private var factory: PrinterFactory 

    private var data: [String: Data] = [:]

    private var states: [KripkeState] = []

    public init(factory: PrinterFactory, delimiter: String = ".") {
        self.delimiter = delimiter
        self.factory = factory
    }

    public func make(structure: KripkeStructureType) {
        if (true == structure.states.isEmpty) {
            return
        }
        self.states = structure.states
        for s: KripkeState in self.states {
            var d: Data = self.data(s)
            d.states.append(s)
        }
        // Print Kripke Structures 
        for t: (key: String, d: Data) in self.data {
            self.printStructure(self.generateData(t.d))
        }
    }

    private func generateData(d: Data) -> Data {
        var d: Data = d
        self.createTrans(d)
        self.createVars(d)
        return d
    }

    private func printStructure(d: Data) {
        var str: String = "MODULE \(d.machine.name)\n\n"
        str += d.vars + d.trans
        let printer: Printer = factory.make(
            "\(d.machine.name).nusmv"
        )
        printer.message(str)
    }

    private func createTrans(d: Data) {
        var d: Data = d
        var lastState: KripkeState = d.states[0]
        var lastPcName: String = getNextName(lastState)
        var states: [KripkeState] = d.states
        states.removeFirst()
        states.forEach {
            let pcName: String = getNextName($0)
            d.trans += getTrans(lastPcName, state: lastState)
            d.trans += getChanges(pcName, state: $0)
            lastState = $0
            lastPcName = pcName
        }
        d.trans += "esac\n"
    }

    private func createVars(d: Data) {
        var d: Data = d
        d.properties.map {
            d.vars += "\($0) : {"
            var pre: Bool = false
            $1.forEach {
                d.vars += (true == pre ? ",\n" : "\n") + "\($0.value)"
                pre = true
            }
            d.vars += "\n};\n\n"
        }
        d.vars += "pc : {\n"
        d.pc.forEach { d.vars += $0 + "\n" }
        d.vars += "};\n\n"
        d.vars += "INIT\n"
        d.vars += "pc=\(d.pc[0])\n"
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
                "\(prep)\(state.machine.name)\(self.delimiter)\(state.fsm.name)\(self.delimiter)\($0)\(app)",
                state: state,
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
                "\(prep)\(state.machine.name)\(self.delimiter)\(state.fsm.name)\(self.delimiter)\(state.state.name)\(self.delimiter)\($0)\(app)",
                state: state,
                p: $1,
                pre: &pre,
                addToProperties: addToProperties
            )
        }
        state.globalProperties.forEach {
            str += generate(
                "\(prep)\(state.machine.name)\(self.delimiter)globals\(self.delimiter)\($0)\(app)",
                state: state,
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
        var d: Data = self.data(state)
        var name: String = 
            "\(d.machine.name)\(self.delimiter)\(state.fsm.name)\(self.delimiter)\(state.state.name)"
        if (nil == d.ringlets[name]) {
            d.ringlets[name] = -1
        }
        d.ringlets[name]! += 1
        name += "\(self.delimiter)R\(d.ringlets[name]!)"
        d.pc.append(name)
        return name
    }

    private func generate(
        name: String,
        state: KripkeState,
        p: KripkeStateProperty,
        inout pre: Bool,
        addToProperties: Bool
    ) -> String {
        if (p.type == .Some) {
            return ""
        }
        if (true == addToProperties) {
            self.addToProperties(name, p: p, state: state)
        }
        var str: String = ""
        if (true == pre) {
           str += " & " 
        }
        str += "\(name)=\(p.value)"
        pre = true
        return str
    }

    private func addToProperties(
        name: String,
        p: KripkeStateProperty,
        state: KripkeState
    ) {
        var d: Data = self.data(state)
        if (nil == d.properties[name]) {
            d.properties[name] = []
        }
        if (false == d.properties[name]!.contains({ $0 == p })) {
            d.properties[name]!.append(p)
        }
    }

    private func data(state: KripkeState) -> Data {
        if (nil == self.data[state.machine.name]) {
            self.data[state.machine.name] = Data(machine: state.machine)
        }
        return self.data[state.machine.name]!
    }

}

private class Data {

    public var properties: [String: [KripkeStateProperty]] = [:]
    public let machine: Machine
    public var states: [KripkeState] = []
    public var str: String = "MODULE main\n\n"
    public var vars: String = "VAR\n\n"
    public var trans: String = "TRANS\ncase\n"
    public var ringlets: [String: Int] = [:]
    public var pc: [String] = []

    public init(machine: Machine) {
        self.machine = machine
    }

}

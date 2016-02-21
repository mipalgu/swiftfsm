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

/**
 *  Print the Kripke Structure into a format supported by NuSMV.
 */
public class NuSMVKripkeStructureView: KripkeStructureView {

    /*
     *  Used to seperate different names when creating namespaces.
     */
    private let delimiter: String

    /*
     *  Used to create the printer that will output the kripke structures.
     */
    private var factory: PrinterFactory 

    /*
     *  A Dictionary containing the data objects for every individual machine
     *  that the structure contains.
     *
     *  The key is the name of the machine and the value is the Data object.
     */
    private var data: [String: Data] = [:]

    /*
     *  All the states within the kripke structure.
     */
    private var states: [KripkeState] = []

    public init(factory: PrinterFactory, delimiter: String = "-") {
        self.delimiter = delimiter
        self.factory = factory
    }

    /**
     *  Print the specified kripke structure.
     */
    public func make(structure: KripkeStructureType) {
        if (true == structure.states.isEmpty) {
            return
        }
        //dprint(structure.states)
        self.data = [:]
        // Create seperate data objects for all the different machines.
        self.states = structure.states
        for s: KripkeState in self.states {
            var d: Data = self.data(s)
            d.states.append(s)
        }
        // Print individual Kripke Structures.
        if (self.data.count > 1) {
            self.generateIndividualStructures()
        }
        // Print Kripke Structures 
        self.generateCombinedStructure()
    }

    /*
     *  Prints a kripke structure for every different machine in
     *  the structure.
     */
    private func generateIndividualStructures() {
        for t: (key: String, d: Data) in self.data {
            self.printStructure(self.generateData(t.d))
        }
    }

    /*
     *  Prints a kripek structure with all the different machines combined into
     *  one.
     */
    private func generateCombinedStructure() {
        var temp: Data = Data(module: "main")
        temp.states = self.states
        self.printStructure(self.generateData(temp))
    }

    /*
     *  Generate the transitions and variables that we need to print the
     *  structure.
     */
    private func generateData(d: Data) -> Data {
        var d: Data = d
        self.createTrans(d)
        self.createVars(d)
        dprint(d.trans)
        return d
    }

    /*
     *  Create a printer using the factory provided and print the structure.
     */
    private func printStructure(d: Data) {
        var str: String = "MODULE \(d.module)\n\n"
        str += d.vars + d.trans
        let printer: Printer = factory.make(
            "\(d.module).nusmv"
        )
        printer.message(str)
    }

    /*
     *  Generate the transition section string.
     *
     *  This is stored within the trans property of the Data Type.
     */
    private func createTrans(d: Data) {
        var d: Data = d
        var states: [KripkeState] = d.states
        var lastState: KripkeState = states[0]
        var lastPCName: String = self.getNextPCName(lastState, d: d)
        states.removeFirst()
        states.forEach {
            d.trans += getTrans(lastState, d: d, pcName: lastPCName)
            lastPCName = getNextPCName($0, d: d)
            d.pc.append(lastPCName)
            d.trans += getChanges(
                $0,
                lastState: lastState,
                d: d,
                pcName: lastPCName
            )
            lastState = $0
        }
        d.trans += "esac\n"
    }

    /*
     *  Get the next pc name.
     *
     *  The name follows the following convention:
     *      `<machine_name><delimiter><fsm_name><delimiter><state_name><delimiter><ringlet_count>`
     */
    private func getNextPCName(state: KripkeState, d: Data) -> String {
        var d: Data = d
        var name: String = self.stateName(state)
        if (nil == d.ringlets[name]) {
            d.ringlets[name] = -1
        }
        d.ringlets[name]! += 1
        return name + "\(self.delimiter)R\(d.ringlets[name]!)"
    }

    private func createChangesPropertyList(
        lastState: KripkeState,
        currentState: KripkeState
    ) -> KripkeStatePropertyList {
        return KripkeStatePropertyList(
            stateProperties: lastState.afterProperties.stateProperties,
            fsmProperties: lastState.afterProperties.fsmProperties,
            globalProperties: currentState.beforeProperties.globalProperties
        )
    }

    /*
     *  Generate the vars section string.
     *
     *  This is stored within the vars property of the Data Type.
     */
    private func createVars(d: Data) {
        self.createPropertiesList(d)
        self.createPCList(d)
        self.createInitList(d)
    }

    private func createPropertiesList(d: Data) {
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
    }

    private func createPCList(d: Data) {
        var d: Data = d
        d.vars += "pc : {"
        d.pc.forEach { d.vars += "\n" + $0 + "," }
        var temp: String.CharacterView = d.vars.characters
        temp.removeLast()
        d.vars = String(temp)
        d.vars += "\n};\n\n"
    }

    private func createInitList(d: Data) {
        var d: Data = d
        d.vars += "INIT\n"
        d.vars += "pc=\(d.pc[0])"
        d.vars += d.properties.flatMap({
            nil == $1.first ? nil : " & \($0)=\($1.first!.value)"
        }).reduce("", combine: +)
        d.vars += "\n\n"
    }

    /*
     *  Generate a String representing a list of all properties and their
     *  values.
     */
    private func getTrans(
        state: KripkeState,
        d: Data,
        pcName: String
    ) -> String {
        // Holds naming convention functions for the different property lists.
        let gen: [([String: KripkeStateProperty], (String) -> String)] = [
            (state.beforeProperties.stateProperties, { "\(self.stateName(state))\(self.delimiter)\($0)" }),
            (state.beforeProperties.fsmProperties, { "\(self.fsmName(state))\(self.delimiter)\($0)" }),
            (state.beforeProperties.globalProperties, { "\(self.globalsName(state))\(self.delimiter)\($0)" })
        ]
        var str: String = ""
        let props: String =
            self.generateProperties(gen, d: d, addToProperties: true)
        str += props
        str += nil == props.characters.first ? " " : " & "
        str += "pc=" + pcName + ":\n"
        return str
    }

    /*
     *  This is similar to `getTrans` where it generates a String representing
     *  a list of all properties and their values, however this list represents
     *  the effects of the transition or in other words the next values of the
     *  properties.
     *
     *  This method would generate something like `next(count)=3` for every
     *  property resulting in a string in the following format:
     *  `next(count)=3 & next(pc)=foo`.
     */
    private func getChanges(
        state: KripkeState,
        lastState: KripkeState,
        d: Data,
        pcName: String
    ) -> String {
        // Holds naming convention functions for each property list.
        let gen: [([String: KripkeStateProperty], (String) -> String)] = [
            (lastState.afterProperties.stateProperties, { "next(\(self.stateName(lastState))\(self.delimiter)\($0))" }),
            (lastState.afterProperties.fsmProperties, { "next(\(self.fsmName(lastState))\(self.delimiter)\($0))" }),
            (state.beforeProperties.globalProperties, { "next(\(self.globalsName(state))\(self.delimiter)\($0))" })
        ]
        var str: String = "    "
        let props: String = 
            self.generateProperties(gen, d: d, addToProperties: false)
        str += props
        str += (nil == props.characters.first) ? " " : " & "
        str += "next(pc)=\(pcName);\n"
        return str
    }

    private func stateName(state: KripkeState) -> String {
        return "\(self.fsmName(state))\(self.delimiter)\(state.state.name)"
    }

    private func fsmName(state: KripkeState) -> String {
        return "\(state.machine.name)\(self.delimiter)\(state.fsm.name)"
    }

    private func globalsName(state: KripkeState) -> String {
        return "\(state.machine.name)\(self.delimiter)globals"
    }

    private func generateProperties(
        list: [([String: KripkeStateProperty], (String) -> String)],
        d: Data,
        addToProperties: Bool
    ) -> String {
        var str: String = ""
        var pre: Bool = false
        // Generate the transitions using the correct naming convention for each
        // property list.
        list.forEach { (properties: [String: KripkeStateProperty], f: (String) -> String) in
            properties.forEach {
                str += self.generate(
                    f($0),
                    d: d,
                    p: $1,
                    pre: &pre,
                    addToProperties: addToProperties
                )
            }
        }
        return str
    }

    /*
     *  Used to create an individual item in the property list of the
     *  transition.
     *
     *  This method therefore creates something like this: `name=val` for the
     *  property.
     */
    private func generate(
        name: String,
        d: Data,
        p: KripkeStateProperty,
        inout pre: Bool,
        addToProperties: Bool
    ) -> String {
        if (p.type == .Some) {
            return ""
        }
        if (true == addToProperties) {
            self.addToProperties(name, p: p, d: d)
        }
        var str: String = ""
        if (true == pre) {
           str += " & " 
        }
        str += "\(name)=\(p.value)"
        pre = true
        return str
    }

    /*
     *  Add the property to the properties list within Data if it has not
     *  already been added.
     */
    private func addToProperties(
        name: String,
        p: KripkeStateProperty,
        d: Data 
    ) {
        var d: Data = d 
        if (nil == d.properties[name]) {
            d.properties[name] = []
        }
        if (false == d.properties[name]!.contains({ $0 == p })) {
            d.properties[name]!.append(p)
        }
    }

    /*
     *  Retrieve/Create the Data object for the specific kripke states machine.
     */
    private func data(state: KripkeState) -> Data {
        if (nil == self.data[state.machine.name]) {
            self.data[state.machine.name] = Data(module: state.machine.name)
        }
        return self.data[state.machine.name]!
    }

}

/*
 *  Is used to easily store the data that is required to generate and print a
 *  Kripke Structure.
 */
private class Data {

    /*
     *  A Dictionary Containing a list of property values.
     *
     *  The key represents the name of the property and the value is an array
     *  of all the possible values of the property.  
     */
    public var properties: [String: [KripkeStateProperty]] = [:]
    
    /*
     *  The name of the module that we are generating.
     */
    public let module: String

    /*
     *  All of the states that belong in this structure.
     */
    public var states: [KripkeState] = []

    /*
     *  The vars section.
     */
    public var vars: String = "VAR\n\n"
    
    /*
     *  The trans section.
     */
    public var trans: String = "TRANS\ncase\n"
    
    /*
     *  Keeps track of how many times an individual state has been run.
     *
     *  The key of the dictionary is a string representing the states fully
     *  namespaced name and the value is how many times it has been run.
     */
    public var ringlets: [String: Int] = [:]
    
    /*
     *  Contains a list of fully namespaced state names with their ringlet
     *  counts added on the end.
     */
    public var pc: [String] = []

    public init(module: String) {
        self.module = module
    }

}

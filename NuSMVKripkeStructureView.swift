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
            self.dataForState(s).states.append(s)
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
        for t: (key: String, value: Data) in self.data {
            self.printStructure(self.generateData(t.value))
        }
    }
    
    /*
     *  Prints a kripek structure with all the different machines combined into
     *  one.
     */
    private func generateCombinedStructure() {
        let temp: Data = Data(module: "main")
        temp.states = self.states
        self.printStructure(self.generateData(temp))
    }

    /*
     *  Generate the transitions and variables that we need to print the
     *  structure.
     */
    private func generateData(_ d: Data) -> Data {
        self.createTrans(d)
        self.createVars(d)
        dprint(d.trans)
        return d
    }

    /*
     *  Create a printer using the factory provided and print the structure.
     */
    private func printStructure(_ d: Data) {
        var str: String = "MODULE \(d.module)\n\n"
        str += d.vars + d.trans
        let printer: Printer = factory.make(id: "\(d.module).nusmv")
        printer.message(str: str)
    }

    /*
     *  Generate the transition section string.
     *
     *  This is stored within the trans property of the Data Type.
     */
    private func createTrans(_ d: Data) {
        var states: [KripkeState] = d.states
        var lastState: KripkeState = states[0]
        var lastPCName: String = self.getNextPCName(lastState, d: d)
        states.removeFirst()
        states.forEach {
            d.trans += getTrans(lastState, d: d, pcName: lastPCName)
            lastPCName = getNextPCName($0, d: d)
            d.trans += getChanges(
                $0,
                lastState: lastState,
                d: d,
                pcName: lastPCName
            )
            lastState = $0
        }
        let _: String = getTrans(lastState, d: d, pcName: lastPCName)
        // Handle the last transition.
        d.trans += "TRUE:\n    next(pc)=\(lastPCName);\nesac\n"
    }

    /*
     *  Get the next pc name.
     *
     *  The name follows the following convention:
     *      `<machine_name><delimiter><fsm_name><delimiter><state_name><delimiter><ringlet_count>`
     */
    private func getNextPCName(_ state: KripkeState, d: Data) -> String {
        var name: String = self.stateName(state)
        if (nil == d.ringlets[name]) {
            d.ringlets[name] = -1
        }
        d.ringlets[name]! += 1
        name += "\(self.delimiter)R\(d.ringlets[name]!)"
        d.pc.append(name)
        return name
    }

    private func createChangesPropertyList(
        _ lastState: KripkeState,
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
    private func createVars(_ d: Data) {
        self.createPropertiesList(d)
        self.createPCList(d)
        self.createInitList(d)
    }

    private func createPropertiesList(_ d: Data) {
        d.properties.forEach {
            d.vars += "\($0) : {"
            var pre: Bool = false
            $1.forEach {
                d.vars += (true == pre ? ",\n" : "\n") + $0 
                pre = true
            }
            d.vars += "\n};\n\n"
        }
    }

    private func createPCList(_ d: Data) {
        d.vars += "pc : {"
        d.pc.forEach { d.vars += "\n" + $0 + "," }
        var temp: String.CharacterView = d.vars.characters
        temp.removeLast()
        d.vars = String(temp)
        d.vars += "\n};\n\n"
    }

    private func createInitList(_ d: Data) {
        d.vars += "INIT\n"
        d.vars += "pc=\(d.pc[0])"
        d.vars += d.initials.map({" & \($0)=\($1)"}).reduce("", combine: +)
        d.vars += "\n\n"
    }

    /*
     *  Generate a String representing a list of all properties and their
     *  values.
     */
    private func getTrans(
        _ state: KripkeState,
        d: Data,
        pcName: String
    ) -> String {
        // Holds naming convention functions for the different property lists.
        let gen: [([String: KripkeStateProperty], (String) -> String)] =
            self.getNamingFunctions(state, list: state.beforeProperties) 
        var str: String = ""
        let props: String = self.generateProperties(
            gen,
            d: d,
            addToProperties: true
        )
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
        _ state: KripkeState,
        lastState: KripkeState,
        d: Data,
        pcName: String
    ) -> String {
        // Add the properties to the data properties list.
        let _: String = self.generateProperties(
            self.getNamingFunctions(
                (lastState, lastState.afterProperties.stateProperties),
                fsmProperties: (lastState, lastState.afterProperties.fsmProperties),
                globalProperties: (state, state.beforeProperties.globalProperties)
            ),
            d: d,
            addToProperties: true
        )
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

    private func getNamingFunctions(
        _ state: KripkeState,
        list: KripkeStatePropertyList
    ) -> [([String: KripkeStateProperty], (String) -> String)] {
        return self.getNamingFunctions(
            (state, list.stateProperties),
            fsmProperties: (state, list.fsmProperties),
            globalProperties: (state, list.globalProperties)
        )
    }

    private func getNamingFunctions(
        _ stateProperties: (KripkeState, [String: KripkeStateProperty]),
        fsmProperties: (KripkeState, [String: KripkeStateProperty]),
        globalProperties: (KripkeState, [String: KripkeStateProperty])
    ) -> [([String: KripkeStateProperty], (String) -> String)] {
        return [
            (stateProperties.1, { "\(self.stateName(stateProperties.0))\(self.delimiter)\($0)" }),
            (fsmProperties.1, { "\(self.fsmName(fsmProperties.0))\(self.delimiter)\($0)" }),
            (globalProperties.1, { "\(self.globalsName(globalProperties.0))\(self.delimiter)\($0)" })
        ]
    }

    private func stateName(_ state: KripkeState) -> String {
        return "\(self.fsmName(state))\(self.delimiter)\(state.state.name)"
    }

    private func fsmName(_ state: KripkeState) -> String {
        return "\(state.machine.name)\(self.delimiter)\(state.fsm.name)"
    }

    private func globalsName(_ state: KripkeState) -> String {
        return "\(state.machine.name)\(self.delimiter)globals"
    }

    private func generateProperties(
        _ list: [([String: KripkeStateProperty], (String) -> String)],
        d: Data,
        addToProperties: Bool
    ) -> String {
        var str: String = ""
        var pre: Bool = false
        // Generate the transitions using the correct naming convention for each
        // property list.
        list.forEach { (properties: [String: KripkeStateProperty], f: (String) -> String) in
            properties.forEach {
                let name: String = f($0)
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
        _ name: String,
        d: Data,
        p: KripkeStateProperty,
        pre: inout Bool,
        addToProperties: Bool
    ) -> String {
        if (false == self.isSupportedType(p.type)) {
            return ""
        }
        var str: String = ""
        if (true == pre) {
           str += " & " 
        }
        let val: String = self.formatPropertyValue(p)
        if (true == addToProperties) {
            self.addToProperties(name, value: val, d: d)
        }
        str += "\(name)=\(val)"
        pre = true
        return str
    }

    private func formatPropertyValue(_ p: KripkeStateProperty) -> String {
        var val: String = "\(p.value)"
        if (.String == p.type) {
            val = "\"" + val + "\""
        }
        if (.Double == p.type || .Float == p.type || .Float80 == p.type) {
            val = "F" + String(val.characters.map({ $0 == "." ? "_" : $0 }))
        }
        return val
    }

    /*
     *  Add the property to the properties list within Data if it has not
     *  already been added.
     */
    private func addToProperties(
        _ name: String,
        value: String,
        d: Data 
    ) {
        if (nil == d.properties[name]) {
            d.properties[name] = []
            d.initials[name] = value
        }
        d.properties[name]!.insert(value)
    }

    /*
     *  Retrieve/Create the Data object for the specific kripke states machine.
     */
    private func dataForState(_ state: KripkeState) -> Data {
        if (nil == self.data[state.machine.name]) {
            self.data[state.machine.name] = Data(module: state.machine.name)
        }
        return self.data[state.machine.name]!
    }

    private func isSupportedType(_ t: KripkeStatePropertyTypes) -> Bool {
        return t == .Bool || t == .Int8 || t == .Int16 || t == .Int32 ||
            t == .Int64 || t == .Int || t == .UInt8 || t == .UInt16 ||
            t == .UInt32 || t == .UInt64 || t == .UInt || t == .Float80 ||
            t == .Float || t == .Double || t == .String
    }

}

/*
 *  Is used to easily store the data that is required to generate and print a
 *  Kripke Structure.
 */
private class Data {

    private var initials: [String: String] = [:]

    /*
     *  A Dictionary Containing a list of property values.
     *
     *  The key represents the name of the property and the value is an array
     *  of all the possible values of the property.  
     */
    private var properties: [String: Set<String>] = [:]
    
    /*
     *  The name of the module that we are generating.
     */
    private let module: String

    /*
     *  All of the states that belong in this structure.
     */
    private var states: [KripkeState] = []

    /*
     *  The vars section.
     */
    private var vars: String = "VAR\n\n"
    
    /*
     *  The trans section.
     */
    private var trans: String = "TRANS\ncase\n"
    
    /*
     *  Keeps track of how many times an individual state has been run.
     *
     *  The key of the dictionary is a string representing the states fully
     *  namespaced name and the value is how many times it has been run.
     */
    private var ringlets: [String: Int] = [:]
    
    /*
     *  Contains a list of fully namespaced state names with their ringlet
     *  counts added on the end.
     */
    private var pc: [String] = []

    private init(module: String) {
        self.module = module
    }

}

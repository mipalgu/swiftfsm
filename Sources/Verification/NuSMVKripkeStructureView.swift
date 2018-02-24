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
import IO
import KripkeStructure

//swiftlint:disable type_body_length
//swiftlint:disable identifier_name
//swiftlint:disable file_length
//swiftlint:disable line_length

/**
 *  Print the Kripke Structure into a format supported by NuSMV.
 */
public class NuSMVKripkeStructureView: KripkeStructureView {

    fileprivate let extractor: NuSMVPropertyExtractor

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
    private var states: [[KripkeState]] = []

    /**
     *  Create a new `NuSMVKripkeStructureView`.
     *
     *  - Parameter factory: Used to create the `Printer` that will output the
     *  NuSMV representation of the `KripkeStructure`.
     *
     *  - Parameter delimiter: Used to place in between identifiers.  For
     *  example, the program counter is represented as:
     *  <machine_name>-<fsm_name>-<state_name>-<snapshot_count> where "-" is the
     *  delimiter.
     */
    public init(extractor: NuSMVPropertyExtractor = NuSMVPropertyExtractor(), factory: PrinterFactory) {
        self.extractor = extractor
        self.factory = factory
    }

    /**
     *  Print the specified kripke structure.
     *
     *  - Parameter structure: The `KripkeStructure` that will be converted to
     *  the NuSMV representation.
     */
    public func make(structure: KripkeStructure) {
        structure.states.forEach {
            $0.forEach {
                print(self.extractor.extract(from: $0.properties))
            }
        }
        /*if true == structure.states.isEmpty {
            return
        }
        self.states = structure.states
        let data: Data = Data(module: "main")
        data.states = self.states
        self.initializeDefaultProperties(data)
        self.printStructure(self.generateData(data))*/
    }
/*
    private func initializeDefaultProperties(_ d: Data) {
        d.states.forEach {
            $0.forEach { (s: KripkeState<AnyScheduleableFiniteStateMachine>) in
                let f = self.createNamingFunction(forState: s)
                s.properties.forEach { (p: (String, KripkeStateProperty)) in
                    if false == self.isSupportedType(p.1.type) {
                        return
                    }
                    let label = f(p.0)
                    let value = self.formatPropertyValue(p.1)
                    if nil == d.latestProperties[label] {
                        d.latestProperties[label] = value
                    }
                }
            }
        }
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
        return d
    }

    /*
     *  Create a printer using the factory provided and print the structure.
     */
    private func printStructure(_ d: Data) {
        var str: String = "MODULE main\n\n"
        str += d.vars + d.trans
        let printer: Printer = factory.make(id: "\(d.module).smv")
        printer.message(str: str)
    }

    /*
     *  Generate the transition section string.
     *
     *  This is stored within the trans property of the Data Type.
     */
    private func createTrans(_ d: Data) {
        //print(d.states.flatMap { $0 })
        print()
        d.states.forEach {
            $0.forEach {
                // Create Trans of current state
                let pcName = self.getNextPCName($0, d: d)
                if nil != d.seen[pcName] {
                    return
                }
                d.seen[pcName] = true
                let trans = getTrans($0, d: d, pcName: pcName)
                if true == $0.targets.isEmpty {
                    return
                }
                d.trans += trans
                // Create Next lists of future states
                var first: Bool = true
                d.trans += $0.targets.reduce("") { (str, state) in
                    var str = str
                    str += true == first ? "\n    (" : " |\n    ("
                    let pc = self.getNextPCName(state, d: d)
                    //print("change state: \(state), pc: \(pc)") 
                    str += self.getChanges(
                        state,
                        d: d,
                        pcName: pc
                    )
                    str += ")"
                    first = false
                    return str
                }
                d.trans += ";\n"
            }
        }
        let lastState = d.states.last!.last!
        let lastPCName = self.getNextPCName(lastState, d: d)
        let _: String = getTrans(lastState, d: d, pcName: lastPCName)
        // Handle the last transition.
        var properties = d.latestProperties
        guard let first = properties.first else {
            d.trans += "TRUE:\n    next(pc)=\(lastPCName);\nesac\n"
            return
        }
        properties[first.key] = nil
        let props: String = properties.reduce("next(\(first.key))=\(first.value)") { $0 + " & next(\($1.0))=\($1.1)" }
        d.trans += "TRUE:\n    " + props + " & next(pc)=\(lastPCName);\nesac\n"
        //print(d.pcTable)
    }

    /*
     *  Get the next pc name.
     *
     *  The name follows the following convention:
     *      `<machine_name><delimiter><fsm_name><delimiter><state_name><delimiter><ringlet_count><delimiter><snapshot_count>`
     */
    private func getNextPCName(_ state: KripkeState<AnyScheduleableFiniteStateMachine>, d: Data) -> String {
        let key = state.targets.reduce(state.description) { $0 + $1.description }
        if let pc = d.pcTable[key] {
            //print("found previous pc: \(pc)")
            //print("state: \(state)")
            return pc
        }
        if nil == d.snapshots[state.id] {
            d.snapshots[state.id] = 0
        }
        let name = state.id + "\(self.delimiter)S\(d.snapshots[state.id]!)"
        d.pc.append(name)
        d.pcTable[key] = name
        d.snapshots[state.id]! += 1
        return name
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
            let arr: [String] = [String]($1).sorted {
                if let lhs = Double($0), let rhs = Double($1) {
                    return lhs < rhs
                }
                return $0 < $1
            }
            arr.forEach {
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
        d.vars += d.initials.map({" & \($0)=\($1)"}).reduce("", +)
        d.vars += "\n\n"
    }

    /*
     *  Generate a String representing a list of all properties and their
     *  values.
     */
    private func getTrans(
        _ state: KripkeState<AnyScheduleableFiniteStateMachine>,
        d: Data,
        pcName: String
    ) -> String {
        self.format(self.trimUnsupported(state.properties), self.createNamingFunction(forState: state)).forEach {
            self.addToLatestProperties(d, $0)
        }
        var str: String = ""
        let props: String = self.generateProperties(d.latestProperties.map({$0}), d: d, addToProperties: true)
        str += props
        str += nil == props.characters.first ? " " : " & "
        str += "pc=" + pcName + ":"
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
        _ state: KripkeState<AnyScheduleableFiniteStateMachine>,
        d: Data,
        pcName: String
    ) -> String {
        // Get the actual names and add to latestProperties.
        self.format(self.trimUnsupported(state.properties), self.createNamingFunction(forState: state)).forEach {
            self.addToLatestProperties(d, $0)
        }
        // Holds naming convention functions for the different property lists.
        let gen: [([String: String], (String) -> String)] = [
            (d.latestProperties, { "next(\($0))"})
        ]
        let formatted = gen.flatMap { (ps: [String: String], f: (String) -> String) -> [(String, String)] in
            ps.map { (f($0.0), $0.1) }
        }
        var str: String = ""
        let props: String = self.generateProperties(formatted, d: d, addToProperties: false)
        str += props
        str += (nil == props.characters.first) ? "" : " & "
        str += "next(pc)=\(pcName)"
        return str
        /*// Add the properties to the data properties list.
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
        var str: String = "    "
        let props: String = 
            self.generateProperties(gen, d: d, addToProperties: false)
        str += props
        str += (nil == props.characters.first) ? " " : " & "
        str += "next(pc)=\(pcName);\n"
        return str*/
    }

    private func createNamingFunction(
        forState state: KripkeState<AnyScheduleableFiniteStateMachine>
    ) -> (String) -> String {
        return {
            self.formatLabel(state.id + self.delimiter + $0)
        }
    }

    private func format(_ ps: [String: KripkeStateProperty], _ f: (String) -> String) -> [(String, String)] {
        return ps.map { (f($0.0), self.formatPropertyValue($0.1)) }
    }

    private func trimUnsupported(_ ps: [String: KripkeStateProperty]) -> [String: KripkeStateProperty] {
        // Remove all unsupported types.
        var d: [String: KripkeStateProperty] = [:]
        ps.forEach {
            if false == self.isSupportedType($0.1.type) {
                return
            }
            d[$0.0] = $0.1
        }
        return d
    }

    private func addToLatestProperties(_ d: Data, _ p: (String, String)) {
        d.latestProperties[p.0] = p.1
    }

    private func generateProperties(_ list: [(String, String)], d: Data, addToProperties: Bool) -> String {
        var str: String = ""
        var pre: Bool = false
        list.forEach {
            str += self.generate(label: $0.0, value: $0.1, pre: pre)
            pre = true
            if false == addToProperties {
                return
            }
            self.addToProperties($0.0, value: $0.1, d: d)
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
    private func generate(label: String, value: String, pre: Bool) -> String {
        var str: String = ""
        if true == pre {
           str += " & "
        }
        str += "\(label)=\(value)"
        return str
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
        if nil == d.properties[name] {
            d.properties[name] = []
            d.initials[name] = value
        }
        d.properties[name]!.insert(value)
    }

    private func isSupportedType(_ t: KripkeStatePropertyTypes) -> Bool {
        if t == .Bool || t == .Int8 || t == .Int16 || t == .Int32 ||
            t == .Int64 || t == .Int || t == .UInt8 || t == .UInt16 ||
            t == .UInt32 || t == .UInt64 || t == .UInt || t == .Float80 ||
            t == .Float || t == .Double || t == .String {
            return true
        }
        switch t {
        case .Compound:
            return true
        case .Collection(let ps):
            if true == ps.isEmpty {
                return true
            }
            let first = ps.first!
            return self.isSupportedType(first.type)
        default:
            return false
        }
    }

}
*/

/*
 *  Is used to easily store the data that is required to generate and print a
 *  Kripke Structure.
 */
fileprivate class Data {

    public var initials: [String: String] = [:]

    /*
     *  A Dictionary Containing a list of property values.
     *
     *  The key represents the name of the property and the value is an array
     *  of all the possible values of the property.  
     */
    public var properties: [String: Set<String>] = [:]

    public var latestProperties: [String: String] = [:]

    /*
     *  The name of the module that we are generating.
     */
    public let module: String

    /*
     *  All of the states that belong in this structure.
     */
    public var states: [[KripkeState]] = []

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
    public var snapshots: [String: UInt] = [:]

    /*
     *  Contains a list of fully namespaced state names with their ringlet
     *  counts added on the end.
     */
    public var pc: [String] = []

    public var pcTable: [String: String] = [:]

    public var seen: [String: Bool] = [:]

    public init(module: String) {
        self.module = module
    }

}

}

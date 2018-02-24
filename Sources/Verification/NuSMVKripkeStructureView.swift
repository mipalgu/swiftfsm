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

/**
 *  Print the Kripke Structure into a format supported by NuSMV.
 */
public class NuSMVKripkeStructureView: KripkeStructureView {

    fileprivate let extractor: NuSMVPropertyExtractor

    /*
     *  Used to create the printer that will output the kripke structures.
     */
    private var factory: PrinterFactory

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
        let plist = self.createPropertiesList(from: self.extractProperties(of: structure.states))
        let trans = self.createTransitions(from: structure.states)
        self.printStructure(properties: plist, initial: "", transitions: trans)
    }

    /*
     *  Create a printer using the factory provided and print the structure.
     */
    private func printStructure(properties: String, initial: String, transitions: String) {
        let module = "MODULE main"
        let contents = module + "\n\n" + properties + "\n\n" + initial + "\n\n" + transitions
        let printer: Printer = factory.make(id: "main.smv")
        printer.message(str: contents)
    }

    private func createTransitions(from states: [KripkeState]) -> String {
        let trans = "TRANS\ncase"
        let endTrans = "esac"
        guard let firstState = states.first else {
            return trans + "\n" + endTrans
        }
        let firstCase = self.createCase(of: firstState)
        let list = states.dropFirst().reduce(firstCase) {
            $0 + "\n" + self.createCase(of: $1)
        }
        return trans + "\n" + list + "\n" + endTrans
    }

    private func createCase(of state: KripkeState) -> String {
        let props = self.extractor.extract(from: state.properties)
        let effects = state.effects.map {
            self.extractor.extract(from: $0)
        }
        guard let firstProp = props.first else {
            return ""
        }
        let firstCondition = firstProp.0 + "=" + firstProp.1
        let conditions = props.reduce(firstCondition) {
            $0 + " & " + $1.0 + "=" + $1.1
        }
        let effectsList = effects.reduce("") { (last: String, props: [String: String]) -> String in
            last + "\n    " + self.createEffect(from: props)
        }
        return conditions + ":" + effectsList
    }

    private func createEffect(from props: [String: String]) -> String {
        guard let firstProp = props.first else {
            return ""
        }
        let firstEffect = "next(" + firstProp.0 + ")=" + firstProp.1
        let effects = props.reduce(firstEffect) {
            $0 + " & next(" + $1.0 + ")=" + $1.1
        }
        return effects + ";"
    }

    private func extractProperties(of states: [KripkeState]) -> [String: Set<String>] {
        var props: [String: Set<String>] = [:]
        states.forEach { (state) in
            let stateProperties = self.extractor.extract(from: state.properties)
            stateProperties.forEach { (key, property) in
                if nil == props[key] {
                    props[key] = []
                }
                props[key]?.insert(property)
            }
        }
        return props
    }

    private func createPropertiesList(from props: [String: Set<String>]) -> String {
        return props.reduce("VAR") {
            guard let first = $1.1.first else {
                return $0 + "\n\n" + "\($1.0) : {};"
            }
            let preList = $0 + "\n\n" + "\($1.0) : {\n"
            let list = $1.1.dropFirst().reduce("    " + first) {
                $0 + ",\n    " + $1
            }
            return preList + list + "\n};"
        }
    }

}

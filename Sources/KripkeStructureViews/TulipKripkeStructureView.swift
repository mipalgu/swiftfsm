/*
 * TulipKripkeStructureView.swift
 * Verification
 *
 * Created by Callum McColl on 22/9/18.
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

/*

import FSM
import IO
import KripkeStructure
import Utilities

public final class TulipKripkeStructureView: KripkeStructureView {
    
    /*
     *  Used to create the printer that will output the kripke structures.
     */
    private var factory: PrinterFactory
    
    fileprivate var cache: [KripkeStatePropertyList: Int] = [:]
    fileprivate var latest: Int = 0
    
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
    public init(factory: PrinterFactory) {
        self.factory = factory
    }
    
    /**
     *  Print the specified kripke structure.
     *
     *  - Parameter structure: The `KripkeStructure` that will be converted to
     *  the NuSMV representation.
     */
    public func make(structure: KripkeStructure) {
        self.cache = [:]
        self.latest = 0
        var content: String = "(tlp \"2.3\"\n"
        let nodeCount = structure.initialStates.count + structure.states.count
        content += "(nb_nodes \(nodeCount))\n"
        content += "(nodes 0..\(nodeCount - 1))\n"
        let states = Array(structure.states.lazy.map { $1 })
        self.populateCache(withStates: states, inStructure: structure)
        content += self.createEdges(fromInitialStates: structure.initialStates)
        content += "\n" + self.createEdgeList(forStates: states, inStructure: structure)
        content += "\n" + self.createPropertyList(forStates: states, inStructure: structure)
        content += "\n" + self.createSizeList(forStates: states, inStructure: structure)
        content += "\n)"
        let printer: Printer = factory.make(id: "kripke_structure.tlp")
        printer.message(str: content)
    }
    
    fileprivate func populateCache(withStates states: [KripkeState], inStructure structure: KripkeStructure) {
        states.enumerated().forEach { self.cache[$1.properties] = structure.initialStates.count + $0 }
    }
    
    fileprivate func createEdges(fromInitialStates initialStates: [KripkeState]) -> String {
        let mapped = initialStates.enumerated().lazy.map { (offset, state) -> String in
            guard let target = self.cache[state.properties] else {
                fatalError("Unable to fetch target id of initial state from cache when creating tulip file.")
            }
            return self.createEdge(id: offset, source: offset, target: target)
        }
        return mapped.combine("") { $0 + "\n" + $1 }
    }
    
    fileprivate func createEdgeList(forStates states: [KripkeState], inStructure structure: KripkeStructure) -> String {
        let mapped = states.enumerated().lazy.flatMap { (offset, state) -> [String] in
            let source = offset + structure.initialStates.count
            return state.effects.map {
                guard let target = self.cache[$0] else {
                    fatalError("Unable to fetch target id of state from cache when creating tulip file.")
                }
                let id = self.latest + structure.initialStates.count
                self.latest += 1
                return self.createEdge(id: id, source: source, target: target)
            }
        }
        return mapped.combine("") { $0 + "\n" + $1 }
    }
    
    fileprivate func createEdge(id: Int, source: Int, target: Int) -> String {
        return "(edge \(id) \(source) \(target))"
    }
    
    fileprivate func createPropertyList(
        forStates states: [KripkeState],
        inStructure structure: KripkeStructure
    ) -> String {
        let start = "(property 0 string \"viewLabel\"\n  (default \"\" \"\")\n"
        let end = ")"
        let mapped = states.enumerated().lazy.map { (offset, state) -> String in
            //swiftlint:disable:next line_length
            return "(node \(offset + structure.initialStates.count) \"\(self.formatProperties(list: state.properties, indent: 1, includeBraces: false) ?? "")\")"
        }
        return start + mapped.combine("") { $0 + "\n" + $1 } + "\n" + end
    }
    
    fileprivate func createSizeList(forStates states: [KripkeState], inStructure structure: KripkeStructure) -> String {
        let start = "(property 0 size \"viewSize\"\n  (default \"(0,0,0)\" \"(1,1,1)\")\n"
        let end = ")"
        let total = states.count + structure.initialStates.count - 1
        let mapped = Array(0...total).lazy.map { "  (node \($0) \"(10000,10000,10000)\")" }
        return start + mapped.combine("") { $0 + "\n" + $1 } + "\n" + end
    }
    
    fileprivate func formatProperties(
        list: KripkeStatePropertyList,
        indent: Int,
        includeBraces: Bool = true
    ) -> String? {
        let indentStr = Array(repeating: " ", count: (indent + 1) * 2).reduce("", +)
        let list = list.sorted { $0.0 < $1.0 }
        let props = list.compactMap { (key: String, val: KripkeStateProperty) -> String? in
            guard let prop = self.formatProperty(val, indent + 1) else {
                return nil
            }
            return "\\n" + indentStr + key + " = " + prop
        }
        if props.isEmpty {
            return nil
        }
        let content = props.combine("") { $0 + "," + $1 }
        let indentStr2 = Array(repeating: " ", count: indent * 2).combine("", +)
        if true == includeBraces {
            return "{" + content + "\\n" + indentStr2 + "}"
        }
        return content + "\\n" + indentStr2
    }
    
    fileprivate func formatProperty(_ prop: KripkeStateProperty, _ indent: Int) -> String? {
        switch prop.type {
        case .EmptyCollection:
            return "[]"
        case .Collection(let collection):
            if collection.isEmpty {
                return "[]"
            }
            let indentStr = Array(repeating: " ", count: indent * 2).reduce("", +)
            let indentStr2 = Array(repeating: " ", count: (indent + 1) * 2).reduce("", +)
            let props = collection.compactMap { (val: KripkeStateProperty) -> String? in
                self.formatProperty(val, indent + 1)
            }
            if props.isEmpty {
                return nil
            }
            return "[\\n" + indentStr2 + props.combine("") { $0 + ",\\n" + indentStr2 + $1 } + "\\n" + indentStr + "]"
        case .Compound(let list):
            return self.formatProperties(list: list, indent: indent + 1)
        default:
            return "\(prop.value)"
        }
    }
    
}
*/

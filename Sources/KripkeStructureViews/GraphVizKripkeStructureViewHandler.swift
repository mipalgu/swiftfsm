/*
 * GraphVizKripkeStructureViewHandler.swift
 * KripkeStructureViews
 *
 * Created by Callum McColl on 17/10/18.
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

import IO
import KripkeStructure
import swift_helpers

public final class GraphVizKripkeStructureViewHandler: GenericKripkeStructureViewHandler {

    public init() {}

    public func handleStart(_: GenericKripkeStructureViewData, usingStream stream: inout OutputStream) {
        stream.write("digraph finite_state_machine {\n")
    }

    public func handleEnd(_: GenericKripkeStructureViewData, usingStream stream: inout OutputStream) {
        stream.write("}")
    }

    public func handleState(
        _ data: GenericKripkeStructureViewData,
        state: KripkeState,
        withId id: Int,
        isInitial: Bool,
        usingStream stream: inout OutputStream
    ) {
        let shape = state.edges.isEmpty ? "doublecircle" : "circle"
        let label = self.formatProperties(list: state.properties, indent: 1, includeBraces: false) ?? "\(id)"
        if true == isInitial {
            stream.write("node [shape=point] si\(id);")
            data.addInitial(id, transitioningTo: id)
        }
        stream.write("node [shape=\(shape), label=\"\(label)\"]; s\(id);\n")
    }

    public func handleInitials(
        _ data: GenericKripkeStructureViewData,
        initials: [(Int, Int)],
        usingStream stream: inout OutputStream
    ) {
        initials.forEach {
            stream.write("si\($0) -> s\($1);\n")
        }
    }

    public func handleEffects(
        _ data: GenericKripkeStructureViewData,
        state: KripkeState,
        withId id: Int,
        usingStream stream: inout OutputStream
    ) {
        func expression(for constraint: ClockConstraint, clockLabel: String) -> String {
            return constraint.expression(
                referencing: clockLabel,
                lessThan: { "\($0) &lt; \($1)" },
                lessThanEqual: { "\($0) &le; \($1)" },
                equal: { "\($0) = \($1)" },
                notEqual: { "\($0) &ne; \($1)" },
                greaterThan: { "\($0) &gt; \($1)" },
                greaterThanEqual: { "\($0) &ge; \($1) " },
                and: { "\($0) &and; \($1)" },
                or: { "\($0) &or; \($1)" },
                implies: { "\($0) &rarr; \($1)" },
                not: { "&not;\($0)" },
                group: { "&#40;\($0)&#41;" }
            )
        }
        state.edges.forEach {
            let target = data.fetchId(of: $0.target)
            let label: String
            if data.usingClocks {
                let time = $0.time == 0 ? nil : $0.time
                var labels: [String] = []
                labels.reserveCapacity(3)
                if let time = time {
                    labels.append("\(time)")
                }
                if let clockName = $0.clockName {
                    if let constraint = $0.constraint, constraint != .equal(value: 0) {
                        labels.append(expression(for: constraint.reduced, clockLabel: clockName))
                    }
                    if $0.resetClock {
                        labels.append("\(clockName) := 0")
                    }
                }
                label = labels.combine("") { $0 + ", " + $1 }
            } else {
                label = ""
            }
            let labelStr = label == "" ? "" : " [ label=\"\(label)\" ]"
            stream.write("s\(id) -> s\(target)\(labelStr);\n")
        }
    }

    public func formatProperties(
        list: KripkeStatePropertyList,
        indent: Int,
        includeBraces: Bool = true,
        ignoreDictionaryInternals: Bool = false
    ) -> String? {
        let indentStr = Array(repeating: " ", count: (indent + 1) * 2).reduce("", +)
        let list = list.sorted { $0.0 < $1.0 }
        let props = list.compactMap { (key: String, val: KripkeStateProperty) -> String? in
            if ignoreDictionaryInternals && key == "__optionalValue" {
                return nil
            }
            guard let prop = self.formatProperty(val, indent + 1) else {
                return nil
            }
            return "\\l" + indentStr + key + " = " + prop
        }
        if props.isEmpty {
            return nil
        }
        let content = props.combine("") { $0 + "," + $1 }
        let indentStr2 = Array(repeating: " ", count: indent * 2).combine("", +)
        if true == includeBraces {
            return "{" + content + "\\l" + indentStr2 + "}"
        }
        return content + "\\l" + indentStr2
    }

    fileprivate func formatProperty(_ prop: KripkeStateProperty, _ indent: Int) -> String? {
        switch prop.type {
        case .Optional(let property):
            guard let property = property else {
                return "nil"
            }
            return self.formatProperty(property, indent) ?? "{}"
        case .EmptyCollection:
            return "[]"
        case .Collection(let collection):
            if collection.isEmpty {
                return "[]"
            }
            let indentStr = Array(repeating: " ", count: indent * 2).reduce("", +)
            let indentStr2 = Array(repeating: " ", count: (indent + 1) * 2).reduce("", +)
            let props = collection.map { (val: KripkeStateProperty) -> String in
                self.formatProperty(val, indent + 1) ?? "{}"
            }
            return "[\\l" + indentStr2 + props.combine("") { $0 + ",\\l" + indentStr2 + $1 } + "\\l" + indentStr + "]"
        case .Compound(let list):
            return self.formatProperties(list: list, indent: indent + 1, ignoreDictionaryInternals: true)
        default:
            return "\(prop.value)"
        }
    }

}

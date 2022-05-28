/*
 * GexfKripkeStructureViewHandler.swift
 * ModelChecking
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

//swiftlint:disable line_length

public final class GexfKripkeStructureViewHandler: GenericKripkeStructureViewHandler {

    public init() {}

    public func handleEffects(
        _ data: GenericKripkeStructureViewData,
        state: KripkeState,
        withId id: Int,
        usingStream stream: inout OutputStream
    ) {
        let source = data.fetchId(of: state.properties)
        state.edges.forEach {
            stream.write(self.createEdge(id: data.nextId(), source: source, constraint: $0.constraint?.description, target: data.fetchId(of: $0.target)))
        }
    }

    public func handleEnd(_: GenericKripkeStructureViewData, usingStream stream: inout OutputStream) {
        let end = """
                    </edges>
                </graph>
            </gexf>
            """
        stream.write(end)
    }

    public func handleInitials(
        _ data: GenericKripkeStructureViewData,
        initials: [(Int, Int)],
        usingStream stream: inout OutputStream
    ) {
        let mid = """
                    </nodes>
                    <edges>\n
            """
        stream.write(mid)
        initials.forEach {
            stream.write(self.createEdge(id: data.nextId(), source: $0, constraint: nil, target: $1))
        }
    }

    public func handleStart(_: GenericKripkeStructureViewData, usingStream stream: inout OutputStream) {
        let start = """
            <?xml version="1.0" encoding="UTF-8"?>
            <gexf xmlns="http://www.gexf.net/1.2draft" version="1.2" xmlns:viz=\"http://www.gexf.net/1.2draft/viz\">
            <graph mode="static" defaultedgetype="directed">
            <nodes>\n
            """
        stream.write(start)
    }

    public func handleState(
        _ data: GenericKripkeStructureViewData,
        state: KripkeState,
        withId id: Int,
        isInitial: Bool,
        usingStream stream: inout OutputStream
    ) {
        let label = self.formatProperties(list: state.properties, includeBraces: false) ?? "\(id)"
        if true == isInitial {
            let initialId = data.nextId()
            stream.write("            <node id=\"\(initialId)\"><viz:color r=\"0\" g=\"0\" b=\"0\" /><viz:size value=\"0.25\" /></node>\n")
            data.addInitial(initialId, transitioningTo: id)
        }
        stream.write("            <node id=\"\(id)\" label=\"\(label)\"><viz:color r=\"255\" g=\"255\" b=\"255\" /><viz:size value=\"1.0\" /></node>\n")
    }

    fileprivate func createEdge(id: Int, source: Int, constraint _: String?, target: Int) -> String {
        return "            <edge id=\"\(id)\" source=\"\(source)\" target=\"\(target)\"><viz:color r=\"0\" g=\"0\" b=\"0\" /><viz:shape value=\"solid\" /></edge>\n"
    }

    fileprivate func formatProperties(list: KripkeStatePropertyList, includeBraces: Bool = true) -> String? {
        let list = list.sorted { $0.0 < $1.0 }
        let props = list.compactMap { (key: String, val: KripkeStateProperty) -> String? in
            guard let prop = self.formatProperty(val) else {
                return nil
            }
            return key + " = " + prop
        }
        if props.isEmpty {
            return nil
        }
        let content = props.combine("") { $0 + "," + $1 }
        if true == includeBraces {
            return "{" + content + "}"
        }
        return content
    }

    fileprivate func formatProperty(_ prop: KripkeStateProperty) -> String? {
        switch prop.type {
        case .Optional(let property):
            guard let property = property else {
                return "Nothing"
            }
            return self.formatProperty(property)
        case .EmptyCollection:
            return "[]"
        case .Collection(let collection):
            if collection.isEmpty {
                return "[]"
            }
            let props = collection.compactMap { (val: KripkeStateProperty) -> String? in
                self.formatProperty(val)
            }
            if props.isEmpty {
                return nil
            }
            return "[" + props.combine("") { $0 + ", " + $1 } + "]"
        case .Compound(let list):
            return self.formatProperties(list: list)
        default:
            return "\(prop.value)"
        }
    }

}

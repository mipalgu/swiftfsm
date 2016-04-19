/*
 * NuSMVKripkeStateParser.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 15/04/2016.
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

public class NuSMVKripkeStateParser: NuSMVKripkeStateParserType {
    
    private let delimiter: String

    private var lasts: [String: KripkeStateProperty] = [:]
    private var ringlets: [String: Int] = [:]

    public init(delimiter: String = "-") {
        self.delimiter = delimiter
    }

    public func parse(module: String, states: [KripkeState]) -> NuSMVData? {
        self.lasts = [:]
        var d: NuSMVData = NuSMVData(module: module)
        for s: KripkeState in states {
            d = self.parseState(d, state: s)
        }
        return d
    }

    private func parseState(d: NuSMVData, state: KripkeState) -> NuSMVData {
        var d = d
        // Compute pc
        d.pc.append(namespacePC(state))
        // Compute properties
        var conditions: [String: KripkeStateProperty] = [:]
        // Changed propertes
        var changes: [String: KripkeStateProperty] = [:]
        // Add the last values of all variables to the conditions.
        for p: (String, KripkeStateProperty) in self.lasts {
            let name: String = self.namespaceProperty(state, property: p.0)
            conditions[name] = p.1
        }
        d = self.parsePropertyList(
            d,
            state: state,
            conditions: &conditions,
            changes: &changes
        )
        return d
    }

    private func parsePropertyList(
        d: NuSMVData,
        state: KripkeState,
        conditions: inout [String: KripkeStateProperty],
        changes: inout [String: KripkeStateProperty]
    ) -> NuSMVData {
        var d = d
        d = self.parseProperties(
            d,
            state: state,
            list: state.beforeProperties.stateProperties,
            cache: &conditions,
            namespace: self.namespaceProperty
        )
        d = self.parseProperties(
            d,
            state: state,
            list: state.beforeProperties.fsmProperties,
            cache: &conditions,
            namespace: self.namespaceFSMProperty
        )
        d = self.parseProperties(
            d,
            state: state,
            list: state.beforeProperties.globalProperties,
            cache: &conditions,
            namespace: self.namespaceGlobalProperty
        )
        d = self.parseProperties(
            d,
            state: state,
            list: state.afterProperties.stateProperties,
            cache: &changes,
            namespace: self.namespaceProperty
        )
        d = self.parseProperties(
            d,
            state: state,
            list: state.afterProperties.fsmProperties,
            cache: &changes,
            namespace: self.namespaceFSMProperty
        )
        if let next: KripkeState = state.target {
            d = self.parseProperties(
                d,
                state: state,
                list: state.beforeProperties.globalProperties,
                cache: &changes,
                namespace: self.namespaceGlobalProperty
            )
        }
        return d
    }

    private func parseProperties(
        d: NuSMVData,
        state: KripkeState,
        list: [String: KripkeStateProperty],
        cache: inout [String: KripkeStateProperty],
        namespace: (KripkeState, property: String) -> String
    ) -> NuSMVData {
        var d = d
        for p: (String, KripkeStateProperty) in list {
            // Calculate the properties namespaced name.
            let name: String = namespace(state, property: p.0)
            // Add property to initials
            d = self.addToInitials(d, name: name, property: p.1)
            // Add property to variables
            d = self.addToVariables(d, name: name, property: p.1)
            // Add property to lasts
            self.lasts[name] = p.1
            // Add property to conditions for transition
            cache[name] = p.1
        }
        return d
    }

    private func addToInitials(d: NuSMVData, name: String, property: KripkeStateProperty) -> NuSMVData {
        var d = d
        if (d.initials[name] != nil) {
            return d
        }
        d.initials[name] = property
        return d
    }

    private func addToVariables(d: NuSMVData, name: String, property: KripkeStateProperty) -> NuSMVData {
        var d = d
        if (d.variables[name] == nil) {
            d.variables[name] = []
        }
        d.variables[name]!.insert(property)
        return d
    }

    /*
     *  Retrieve the ringlet number for a particular state.
     */
    private func ringlet(state: KripkeState) -> Int {
        if (nil == self.ringlets[state.state.name]) {
            self.ringlets[state.state.name] = 0
        }
        let temp: Int = self.ringlets[state.state.name]!
        self.ringlets[state.state.name]! += 1
        return temp
    }

    private func namespacePC(state: KripkeState) -> String {
        return "\(self.namespaceState(state))\(self.delimiter)R\(self.ringlet(state))"
    }

    private func namespaceFSM(state: KripkeState) -> String {
        return "\(state.machine.name)\(self.delimiter)\(state.fsm.name)"
    }

    private func namespaceState(state: KripkeState) -> String {
        return "\(self.namespaceFSM(state))\(self.delimiter)\(state.state.name)"
    }

    private func namespaceGlobals(state: KripkeState) -> String {
        return "\(state.machine.name)\(self.delimiter)globals"
    }

    private func namespaceFSMProperty(state: KripkeState, property: String) -> String {
        return "\(self.namespaceFSM(state))\(self.delimiter)\(property)"
    }

    private func namespaceGlobalProperty(state: KripkeState, property: String) -> String {
        return "\(self.namespaceGlobals(state))\(self.delimiter)\(property)"
    }

    private func namespaceProperty(
        state: KripkeState,
        property: String
    ) -> String {
        return "\(self.namespaceState(state))\(self.delimiter)\(property)"
    }

}

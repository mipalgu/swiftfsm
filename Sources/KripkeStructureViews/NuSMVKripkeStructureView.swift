/*
 * NuSMVKripkeStructureView.swift
 * ModelChecking
 *
 * Created by Callum McColl on 15/10/18.
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

import Hashing
import IO
import KripkeStructure
import swift_helpers
import Utilities

#if os(macOS)
import Darwin
#else
import Glibc
import Verification
#endif

import SQLite

public final class NuSMVKripkeStructureView: KripkeStructureView {

    private struct DB {

        private let db: Connection

        private let properties: PropertiesTable

        private let values: ValuesTable

        var propertyNames: AnySequence<String> {
            AnySequence { () -> AnyIterator<String> in
                let iterator = self.properties.properties.makeIterator()
                return AnyIterator {
                    iterator.next().map(\.1)
                }
            }
        }

        var propertyValues: AnySequence<(String, AnySequence<String>)> {
            AnySequence { () -> AnyIterator<(String, AnySequence<String>)> in
                let iterator = self.properties.properties.makeIterator()
                return AnyIterator {
                    guard let (id, name) = iterator.next() else {
                        return nil
                    }
                    return (name, values.values(forProperty: id))
                }
            }
        }

        init(db: Connection) {
            self.db = db
            self.properties = PropertiesTable(db: db)
            self.values = ValuesTable(db: db)
        }

        func insertIfNotExists(property: String, value: String) throws {
            let id = try properties.insertIfNotExists(property: property)
            try values.insertIfNotExists(value: value, forProperty: id)
        }

        func reset() throws {
            try values.reset()
            try properties.reset()
        }

    }

    private struct PropertiesTable {

        private let db: Connection

        private let table: Table = Table("Properties")

        private let id: Expression<Int64> = Expression<Int64>("id")

        private let name: Expression<String> = Expression<String>("name")

        var properties: AnySequence<(Int64, String)> {
            return AnySequence { () -> AnyIterator<(Int64, String)> in
                let results = try! db.prepare(table.select(id, name).order(name.asc))
                let iterator = results.makeIterator()
                return AnyIterator {
                    iterator.next().map { try! ($0.get(id), $0.get(name))  }
                }
            }
        }

        init(db: Connection) {
            self.db = db
        }

        @discardableResult
        func insertIfNotExists(property: String) throws -> Int64 {
            var id: Int64 = -1
            try db.transaction {
                if let row = try db.pluck(table.select(self.id).where(name == property)) {
                    id = try row.get(self.id)
                    return
                }
                id = try db.run(table.insert([
                    name <- property
                ]))
            }
            return id
        }

        func reset() throws {
            try db.run(table.drop(ifExists: true))
            try db.run(table.create { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(name, unique: true)
            })
        }

    }

    private struct ValuesTable {

        private let db: Connection

        private let table: Table = Table("Values")

        private let id: Expression<Int64> = Expression<Int64>("id")

        private let value: Expression<String> = Expression<String>("value")

        private let property: Expression<Int64> = Expression<Int64>("property")

        init(db: Connection) {
            self.db = db
        }

        @discardableResult
        func insertIfNotExists(value valueStr: String, forProperty propertyId: Int64) throws -> Int64 {
            var id: Int64 = -1
            try db.transaction {
                if let row = try db.pluck(table.select(self.id).where(value == valueStr && property == propertyId)) {
                    id = try row.get(self.id)
                    return
                }
                id = try db.run(table.insert([
                    value <- valueStr,
                    property <- propertyId
                ]))
            }
            return id
        }

        func reset() throws {
            try db.run(table.drop(ifExists: true))
            try db.run(table.create { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(value)
                t.column(property)
                t.foreignKey(
                    property,
                    references: Table("Properties"), Expression<Int64>("id"),
                    update: .cascade,
                    delete: .cascade
                )
            })
            try db.run(table.createIndex(value, property, unique: true))
        }

        func values(forProperty propertyId: Int64) -> AnySequence<String> {
            return AnySequence<String> { () -> AnyIterator<String> in
                let results = try! db.prepare(table.select(value).where(property == propertyId).order(value.asc))
                let iterator = results.makeIterator()
                return AnyIterator {
                    iterator.next().map { try! $0.get(value)  }
                }
            }
        }

    }

    fileprivate let extractor: PropertyExtractor<NuSMVPropertyFormatter>

    fileprivate let identifier: String

    fileprivate let outputStreamFactory: OutputStreamFactory
    
    fileprivate var stream: OutputStream!
    
    private var clocks: Set<String> = Set()
    
    private var usingClocks: Bool = false

    fileprivate var firstState: KripkeState?

    private let db: DB

    private var store: KripkeStructure! = nil

    public init(
        identifier: String,
        extractor: PropertyExtractor<NuSMVPropertyFormatter> = PropertyExtractor(formatter: NuSMVPropertyFormatter()),
        outputStreamFactory: OutputStreamFactory = FileOutputStreamFactory()
    ) {
        self.identifier = identifier
        self.extractor = extractor
        self.outputStreamFactory = outputStreamFactory
        let name = identifier.components(separatedBy: .whitespacesAndNewlines).joined(separator: "-")
        let db = try! Connection("\(name).nusmv.sqlite3")
        self.db = DB(db: db)
        try! self.db.reset()
    }

    public func generate(store: KripkeStructure, usingClocks: Bool) throws {
        self.reset(usingClocks: usingClocks)
        self.store = store
        for state in store.states {
            self.commit(state: state)
        }
        self.finish()
    }

    private func reset(usingClocks: Bool) {
        self.clocks = ["c"]
        self.usingClocks = usingClocks
        self.stream = self.outputStreamFactory.make(id: self.identifier + ".smv")
        try! self.db.reset()
        self.firstState = nil
        self.store = nil
    }

    private func commit(state: KripkeState) {
        if nil == self.firstState {
            self.firstState = state
        }
        state.edges.lazy.compactMap { $0.clockName }.forEach {
            let clockName = self.extractor.convert(label: $0)
            self.clocks.insert(clockName)
        }
        let props = self.extractor.extract(from: state.properties)
        for (key, value) in props {
            try! self.db.insertIfNotExists(property: key, value: value)
        }
    }

    private func finish() {
        defer { self.stream.close() }
        self.stream.flush()
        if self.usingClocks {
            self.stream.write("@TIME_DOMAIN continuous\n\n")
        }
        self.stream.write("MODULE main\n\n")
        var outputStream: TextOutputStream = self.stream
        self.createPropertiesList(usingStream: &outputStream)
        self.createInitial(usingStream: &outputStream)
        self.createTransitions(writingTo: &outputStream)
        self.stream.flush()
    }

    fileprivate func createPropertiesList(usingStream stream: inout TextOutputStream) {
        if self.usingClocks {
            stream.write("VAR sync: real;\n")
            stream.write("INVAR TRUE -> sync >= 0;\n\n")
            stream.write("VAR c: clock;\n")
            stream.write("INVAR TRUE -> c >= 0;\n")
            stream.write("INVAR TRUE -> c <= sync;\n\n")
            self.clocks.lazy.filter { $0 != "c" }.sorted().forEach {
                stream.write("VAR \($0): real;\n")
                stream.write("VAR \($0)-time: clock;\n")
                stream.write("INVAR TRUE -> \($0)-time >= c;\n\n")
            }
        }
        for (property, values) in self.db.propertyValues {
            guard let first = values.first(where: { _ in true }) else {
                stream.write("\(property) : {};\n\n")
                return
            }
            stream.write("VAR \(property) : {\n")
            stream.write("    " + first)
            values.dropFirst().forEach {
                stream.write(",\n    " + $0)
            }
            stream.write("\n};\n\n")
        }
    }

    fileprivate func createInitial(usingStream stream: inout TextOutputStream) {
        if nil == self.store.initialStates.first(where: { _ in true }) {
            stream.write("INIT();\n")
            return
        }
        let allClocks = self.usingClocks ? self.clocks.sorted() : []
        stream.write("INIT\n")
        let initials = self.store.initialStates.lazy.map {
            var props = self.extractor.extract(from: $0.properties)
            if self.usingClocks {
                props["sync"] = "0"
                props["c"] = "0"
                allClocks.lazy.filter { $0 != "c" }.forEach {
                    props[$0] = "0"
                    props[$0 + "-time"] = "0"
                }
            }
            props["status"] = "\"executing\""
            return "(" + self.createConditions(of: props) { $0 + "\n    & " + $1 } + ")"
        }.sorted().combine("") { $0 + "\n| " + $1 }
        stream.write(initials + ";")
        stream.write("\n\n")
    }

    fileprivate func createTransitions(
        writingTo outputStream: inout TextOutputStream
    ) {
        let cases = self.store.states.lazy.compactMap { (state) -> String? in
            guard let content = self.createCase(of: state) else {
                return nil
            }
            return content
        }
        for str in cases.sorted() {
            outputStream.write(str)
            outputStream.write("\n")
        }
        self.store.acceptingStates.forEach {
            let props = self.extractor.extract(from: $0.properties)
            let conditions = self.createAcceptingTansition(for: props)
            outputStream.write(conditions + "\n\n")
        }
        if self.usingClocks {
            outputStream.write(self.createWaitCase() + "\n\n")
        }
        outputStream.write("TRANS status = \"finished\" -> next(status) = \"finished\";\n\n")
        outputStream.write("TRANS status = \"error\" -> next(status) = \"error\";\n\n")
    }

    fileprivate func createCase(of state: KripkeState) -> String? {
        if state.edges.isEmpty {
            return nil
        }
        var cases: [String: Set<String>] = [:]
        cases.reserveCapacity(state.edges.count)
        var urgentCases: [String: Set<String>] = [:]
        urgentCases.reserveCapacity(state.edges.count)
        var sourceProps = self.extractor.extract(from: state.properties)
        state.edges.forEach { edge in
            var constraints: [String: ClockConstraint] = [:]
            if self.usingClocks, let referencingClock = edge.clockName, let constraint = edge.constraint {
                let clockName = self.extractor.convert(label: referencingClock)
                constraints[clockName] = constraint
            }
            
            let targetProps = self.extractor.extract(from: edge.target)
            var newCases: [String: String] = [:]
            newCases.reserveCapacity(2)
            if self.usingClocks {
                var sourceProps = sourceProps
                sourceProps["status"] = "\"executing\""
                let conditions = self.createConditions(of: sourceProps, constraints: constraints)
                newCases[conditions] = self.createEffect(from: ["status": "\"waiting\""], duration: edge.time)
                sourceProps["status"] = "\"waiting\""
                let executingCondition = self.createConditions(of: sourceProps, constraints: constraints)
                var targetProps = targetProps
                targetProps["c"] = "0"
                targetProps["sync"] = "0"
                targetProps["status"] = "\"executing\""
                newCases[executingCondition] = self.createEffect(from: targetProps, clockName: edge.clockName, resetClock: edge.resetClock, readTime: edge.takeSnapshot)
            } else {
                let conditions = self.createConditions(of: sourceProps, constraints: constraints)
                newCases[conditions] = self.createEffect(from: targetProps)
            }
            for (conditions, effect) in newCases {
                if nil == cases[conditions] {
                    cases[conditions] = [effect]
                } else {
                    cases[conditions]?.insert(effect)
                }
            }
            /*let transition = "TRANS " + conditions + "\n    -> " + effect
            return transition + ";\n"*/
        }
        func combine(label: String) -> (String, Set<String>) -> String? {
            return { (condition, effects) in
                let effect = effects.sorted().lazy.map { "(" + $0 + ")" }.combine("") { $0 + "\n    | " + $1  }
                if effect.isEmpty {
                    return nil
                }
                return label + " " + condition + "\n    -> (" + effect + ");\n"
            }
        }
        let transitions = cases.compactMap(combine(label: "TRANS"))
        let urgentTransitions = urgentCases.compactMap(combine(label: "URGENT"))
        let combined = (transitions + urgentTransitions).sorted().combine("") { $0 + "\n" + $1 }
        return combined.isEmpty ? nil : combined
    }
    
    private func createWaitCase() -> String {
        let condition = "TRANS c < sync"
        let extras = self.usingClocks ? ["next(sync) = sync", "next(c) = sync"] : []
        let clockNames = self.clocks.subtracting(["c"])
        let fullList = (Array(self.db.propertyNames) + Array(clockNames)) + clockNames.subtracting(["c"]).map { $0 + "-time" }
        let effects = fullList.sorted().map { "next(" + $0 + ") = " + $0 } + extras
        let effectList = effects.combine("") { $0 + "\n    & " + $1 }
        return condition + "\n    -> " + effectList + ";"
    }
    
    private func createAcceptingTansition(for props: [String: String]) -> String {
        let condition = self.createConditions(of: props)
        let effect = self.createAcceptingEffect(for: props)
        return "TRANS " + condition + "\n    -> " + effect + ";"
    }
    
    private func createAcceptingEffect(for props: [String: String]) -> String {
        var targetProps = Dictionary<String, String>(minimumCapacity: props.count + self.clocks.count)
        props.forEach {
            targetProps[$0.0] = $0.0
        }
        if self.usingClocks {
            targetProps["c"] = "c"
            self.clocks.lazy.filter { $0 != "c" }.forEach {
                targetProps[$0] = $0
                targetProps[$0 + "-time"] = $0 + "-time"
            }
        }
        targetProps["status"] = "\"finished\""
        return self.createEffect(from: targetProps)
    }

    fileprivate func createConditions(of props: [String: String], constraints: [String: ClockConstraint] = [:], combine: (String, String) -> String = { $0 + " & " + $1 }) -> String {
        var props = props
        if self.usingClocks, nil == props["c"] {
            props["c"] = "sync"
        }
        if nil == props["status"] {
            props["status"] = "\"executing\""
        }
        let propValues = props.sorted { $0.key <= $1.key }.map { $0 + " = " + $1 }
        let constraintValues = constraints.sorted { $0.key <= $1.key }.map { "(" + self.expression(for: $1.reduced, referencing: $0) + ")" }
        return (propValues + constraintValues).combine("", combine)
    }
    
    private func expression(for constraint: ClockConstraint, referencing label: String) -> String {
        return constraint.expression(referencing: label, equal: { $0 + "=" + $1 }, and: { $0 + " & " + $1 }, or: { $0 + " | " + $1 })
    }

    fileprivate func createEffect(from props: [String: String], clockName: String? = nil, resetClock: Bool = false, duration: UInt? = nil, readTime: Bool = false, forcePC: String? = nil) -> String {
        var props = props
        if nil == props["status"] {
            props["status"] = "\"executing\""
        }
        if self.usingClocks {
            if nil == props["c"] {
                props["c"] = "0"
            }
            if let rawClockName = clockName {
                let clockName = self.extractor.convert(label: rawClockName)
                if resetClock {
                    props[clockName + "-time"] = "0"
                }
                if readTime {
                    props[clockName] = resetClock ? "0" : clockName + "-time"
                }
            }
            if let duration = duration {
                props["sync"] = "\(duration)"
            } else {
                props["sync"] = props["sync"] ?? "sync"
            }
        }
        let allKeys: Set<String>
        if self.usingClocks {
            allKeys = Set(self.db.propertyNames).union(self.clocks).union(Set(self.clocks.lazy.filter { $0 != "c" }.map { $0 + "-time" }))
        } else {
            allKeys = Set(self.db.propertyNames)
        }
        let missingKeys = allKeys.subtracting(Set(props.keys))
        missingKeys.forEach {
            props[$0] = $0
        }
        return props.sorted { $0.key <= $1.key }.lazy.map {
            if let newPC = forcePC, $0.key == "pc" {
                return "next(pc)=" + newPC
            }
            return "next(" + $0.key + ")=" + $0.value
        }.combine("") { $0 + "\n    & " + $1}
    }

}

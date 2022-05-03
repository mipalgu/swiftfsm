/*
 * SQLitePersistentStore.swift
 * Verification
 *
 * Created by Callum McColl on 3/5/2022.
 * Copyright © 2022 Callum McColl. All rights reserved.
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

#if canImport(Foundation) && !NO_FOUNDATION && canImport(SQLite) && !NO_SQLITE

import SQLite
import Foundation
import KripkeStructure

struct SQLitePersistentStore {
    
    struct StatesTable {
        
        let table: Table
        
        let id: Expression<Int64>
        
        let isInitial: Expression<Bool>
        
        let propertyList: Expression<String>
        
    }
    
    struct EdgesTable {
        
        let table: Table
        
        let id: Expression<Int64>
        
        let clockName: Expression<String?>
        
        let constraint: Expression<String?>
        
        let resetClock: Expression<Bool>
        
        let takeSnapshot: Expression<Bool>
        
        let time: Expression<Int64>
        
        let target: Expression<Int64>
        
    }
    
    private let db: Connection
    
    private let states: StatesTable
    
    private let edges: EdgesTable
    
    private let encoder = JSONEncoder()
    
    private let decoder = JSONDecoder()
    
    init(named name: String) throws {
        let name = name.components(separatedBy: .whitespacesAndNewlines).joined(separator: "-")
        let db = try Connection("/tmp/swiftfsm/\(name).sqlite3")

        let states = StatesTable(
            table: Table("States"),
            id: Expression<Int64>("id"),
            isInitial: Expression<Bool>("isInitial"),
            propertyList: Expression<String>("propertyList")
        )
        try db.run(states.table.drop(ifExists: true))
        
        let edges = EdgesTable(
            table: Table("Edges"),
            id: Expression<Int64>("id"),
            clockName: Expression<String?>("clockName"),
            constraint: Expression<String?>("constraint"),
            resetClock: Expression<Bool>("resetClock"),
            takeSnapshot: Expression<Bool>("takeSnapshot"),
            time: Expression<Int64>("time"),
            target: Expression<Int64>("target")
        )
        try db.run(edges.table.drop(ifExists: true))
        
        try db.run(states.table.create { t in
            t.column(states.id, primaryKey: true)
            t.column(states.isInitial)
            t.column(states.propertyList, unique: true)
        })
        
        try db.run(states.table.createIndex(states.isInitial))
        
        try db.run(edges.table.create { (t: TableBuilder) in
            t.column(edges.id, primaryKey: true)
            t.column(edges.clockName)
            t.column(edges.constraint)
            t.column(edges.resetClock)
            t.column(edges.takeSnapshot)
            t.column(edges.time)
            t.column(edges.target)
            t.foreignKey(
                edges.target,
                references: states.table,
                states.id,
                update: .cascade,
                delete: .cascade
            )
        })
        self.db = db
        self.states = states
        self.edges = edges
    }
    
    func add(edge: KripkeEdge, to propertyList: KripkeStatePropertyList) throws {
        guard let (id, state) = try self.state(for: propertyList) else {
            fatalError("Unable to fetch state for property list: \(propertyList)")
        }
        state.addEdge(edge)
        let newRows: [[Setter]] = try state.edges.map {
            [
                edges.clockName <- $0.clockName,
                edges.constraint <- try $0.constraint.flatMap { try String(data: encoder.encode($0), encoding: .utf8) },
                edges.resetClock <- $0.resetClock,
                edges.takeSnapshot <- $0.takeSnapshot,
                edges.time <- Int64($0.time),
                edges.target <- id
            ]
        }
        try db.transaction {
            try db.run(edges.table.filter(edges.target == id).delete())
            try db.run(edges.table.insertMany(newRows))
        }
    }
    
    func state(for propertyList: KripkeStatePropertyList) throws -> KripkeState? {
        try state(for: propertyList)?.1
    }
    
    private func state(for propertyList: KripkeStatePropertyList) throws -> (Int64, KripkeState)? {
        guard let propertyListStr = try String(data: encoder.encode(propertyList), encoding: .utf8) else {
            fatalError("Unable to encode propert list \(propertyList)")
        }
        let rows = try db.prepare(states.table
            .select(states.table[*], edges.table[*])
            .where(states.propertyList == propertyListStr)
        )
        guard let first = rows.first(where: { _ in true }) else {
            return nil
        }
        let id = try first.get(states.table[states.id])
        let isInitial = try first.get(states.table[states.isInitial])
        let edgeSet: Set<KripkeEdge> = try Set(rows.map { row in
            let clockName = try row.get(edges.table[edges.clockName])
            let constraintStr = try row.get(edges.table[edges.constraint])
            let constraint = try constraintStr?.data(using: .utf8).map { try decoder.decode(Constraint<UInt>.self, from: $0) }
            let resetClock = try row.get(edges.table[edges.resetClock])
            let takeSnapshot = try row.get(edges.table[edges.takeSnapshot])
            let time = try UInt(row.get(edges.table[edges.time]))
            return KripkeEdge(
                clockName: clockName,
                constraint: constraint,
                resetClock: resetClock,
                takeSnapshot: takeSnapshot,
                time: time,
                target: propertyList
            )
        })
        let state = KripkeState(isInitial: isInitial, properties: propertyList)
        state.edges = edgeSet
        return (id, state)
    }
    
    func edges(for propertyList: KripkeStatePropertyList) throws -> Set<KripkeEdge> {
        guard let propertyListStr = try String(data: encoder.encode(propertyList), encoding: .utf8) else {
            fatalError("Unable to encode propert list \(propertyList)")
        }
        let rows = try db.prepare(states.table
            .select(edges.table[*])
            .where(states.table[states.propertyList] == propertyListStr)
            .where(states.table[states.id] == edges.table[edges.target])
        )
        let edgeSet: Set<KripkeEdge> = try Set(rows.map { row in
            let clockName = try row.get(edges.table[edges.clockName])
            let constraintStr = try row.get(edges.table[edges.constraint])
            let constraint = try constraintStr?.data(using: .utf8).map { try decoder.decode(Constraint<UInt>.self, from: $0) }
            let resetClock = try row.get(edges.table[edges.resetClock])
            let takeSnapshot = try row.get(edges.table[edges.takeSnapshot])
            let time = try UInt(row.get(edges.table[edges.time]))
            return KripkeEdge(
                clockName: clockName,
                constraint: constraint,
                resetClock: resetClock,
                takeSnapshot: takeSnapshot,
                time: time,
                target: propertyList
            )
        })
        return edgeSet
    }
    
}

#endif

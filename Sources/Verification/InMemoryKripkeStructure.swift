/*
 * InMemoryKripkeStructure.swift
 * Verification
 *
 * Created by Callum McColl on 6/6/2022.
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

import KripkeStructure

public final class InMemoryKripkeStructure: MutableKripkeStructure {

    public let identifier: String

    private var latestId: Int64 = 0

    private var ids: [KripkeStatePropertyList: Int64] = [:]

    private var jobs: Set<KripkeStatePropertyList> = []

    var allStates: [Int64: (KripkeStatePropertyList, Bool, Set<KripkeEdge>)] = [:]

    public var acceptingStates: AnySequence<KripkeState> {
        AnySequence(states.filter { $0.edges.isEmpty })
    }

    public var initialStates: AnySequence<KripkeState> {
        AnySequence(states.filter { $0.isInitial })
    }

    public var states: AnySequence<KripkeState> {
        AnySequence(allStates.keys.map {
            try! self.state(for: $0)
        })
    }

    init(identifier: String) {
        self.identifier = identifier
    }

    init(identifier: String, states: Set<KripkeState>) throws {
        self.identifier = identifier
        for state in states {
            let id = try self.add(state.properties, isInitial: state.isInitial)
            for edge in state.edges {
                try self.add(edge: edge, to: id)
            }
        }
    }

    public func add(_ propertyList: KripkeStatePropertyList, isInitial: Bool) throws -> Int64 {
        let id = try id(for: propertyList)
        if nil == allStates[id] {
            allStates[id] = (propertyList, isInitial, [])
        }
        return id
    }

    public func add(edge: KripkeEdge, to id: Int64) throws {
        allStates[id]?.2.insert(edge)
    }

    public func exists(_ propertyList: KripkeStatePropertyList) throws -> Bool {
        return nil != ids[propertyList]
    }

    public func data(for propertyList: KripkeStatePropertyList) throws -> (Int64, KripkeState) {
        let id = try id(for: propertyList)
        return try (id, state(for: id))
    }

    public func id(for propertyList: KripkeStatePropertyList) throws -> Int64 {
        if let id = ids[propertyList] {
            return id
        }
        let id = latestId
        latestId += 1
        ids[propertyList] = id
        return id
    }

    public func inCycle(_ job: Job) throws -> Bool {
        let plist = KripkeStatePropertyList(job)
        let cycle = jobs.contains(plist)
        jobs.insert(plist)
        return cycle
    }

    public func state(for id: Int64) throws -> KripkeState {
        guard let (plist, isInitial, edges) = allStates[id] else {
            fatalError("State does not exist")
        }
        let state = KripkeState(isInitial: isInitial, properties: plist)
        for edge in edges {
            state.addEdge(edge)
        }
        return state
    }


}

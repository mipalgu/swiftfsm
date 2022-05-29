/*
 * GenericKripkeStructureView.swift
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

import Hashing
import IO
import KripkeStructure

public final class GenericKripkeStructureView<Handler: GenericKripkeStructureViewHandler>: KripkeStructureView {

    fileprivate let handler: Handler

    fileprivate let inputOutputStreamFactory: InputOutputStreamFactory

    fileprivate let outputStreamFactory: OutputStreamFactory

    fileprivate var edgeStream: InputOutputStream!

    fileprivate var combinedStream: OutputStream!

    fileprivate let edgeFilename: String

    fileprivate let filename: String

    public init(
        handler: Handler,
        inputOutputStreamFactory: InputOutputStreamFactory = FileInputOutputStreamFactory(),
        outputStreamFactory: OutputStreamFactory = FileOutputStreamFactory(),
        edgeFilename: String,
        filename: String
    ) {
        self.handler = handler
        self.inputOutputStreamFactory = inputOutputStreamFactory
        self.outputStreamFactory = outputStreamFactory
        self.edgeFilename = edgeFilename
        self.filename = filename
    }

    public func generate(store: KripkeStructure, usingClocks: Bool) throws {
        try self.reset(store: store, usingClocks: usingClocks)
        for state in try store.states {
            try self.commit(store: store, state: state, usingClocks: usingClocks)
        }
        try self.finish(store: store)
    }

    private func reset(store: KripkeStructure, usingClocks: Bool) throws {
        self.edgeStream = self.inputOutputStreamFactory.make(id: self.edgeFilename)
        self.combinedStream = self.outputStreamFactory.make(id: self.filename)
        try self.handler.handleStart(store, usingStream: &self.combinedStream)
    }

    private func commit(store: KripkeStructure, state: KripkeState, usingClocks: Bool) throws {
        let id = try store.id(for: state.properties)
        try self.handler.handleState(
            store,
            state: state,
            withId: id,
            isInitial: state.isInitial,
            usingStream: &self.combinedStream
        )
        var edgeOutputStream: OutputStream = self.edgeStream
        try self.handler.handleEffects(store, state: state, withId: id, usingClocks: usingClocks, usingStream: &edgeOutputStream)
    }

    private func finish(store: KripkeStructure) throws {
        try self.handler.handleInitials(store, initials: store.initialStates, usingStream: &self.combinedStream)
        self.edgeStream.flush()
        self.edgeStream.rewind()
        while let line = self.edgeStream.readLine() {
            self.combinedStream.write(line)
            self.combinedStream.write("\n")
        }
        try self.handler.handleEnd(store, usingStream: &self.combinedStream)
        self.combinedStream.flush()
        self.edgeStream.close()
        self.combinedStream.close()
    }

}

/*extension GenericKripkeStructureView where Handler == GexfKripkeStructureViewHandler {

    public convenience init(
        inputOutputStreamFactory: InputOutputStreamFactory = FileInputOutputStreamFactory(),
        outputStreamFactory: OutputStreamFactory = FileOutputStreamFactory(),
        edgeFilename: String = "kripke_structure.edges.gexf",
        filename: String = "kripke_structure.gexf"
    ) {
        self.init(
            handler: GexfKripkeStructureViewHandler(),
            inputOutputStreamFactory: inputOutputStreamFactory,
            outputStreamFactory: outputStreamFactory,
            edgeFilename: edgeFilename,
            filename: filename
        )
    }

}*/

extension GenericKripkeStructureView where Handler == GraphVizKripkeStructureViewHandler {

    public convenience init(
        inputOutputStreamFactory: InputOutputStreamFactory = FileInputOutputStreamFactory(),
        outputStreamFactory: OutputStreamFactory = FileOutputStreamFactory(),
        edgeFilename: String = "kripke_structure.edges.gv",
        filename: String = "kripke_structure.gv"
    ) {
        self.init(
            handler: GraphVizKripkeStructureViewHandler(),
            inputOutputStreamFactory: inputOutputStreamFactory,
            outputStreamFactory: outputStreamFactory,
            edgeFilename: edgeFilename,
            filename: filename
        )
    }

}

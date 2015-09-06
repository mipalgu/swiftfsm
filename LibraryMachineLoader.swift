/*
 * LibraryMachineLoader.swift
 * swiftfsm
 *
 * Created by Callum McColl on 26/08/2015.
 * Copyright © 2015 Callum McColl. All rights reserved.
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

import Swift_FSM

public class LibraryMachineLoader: MachineLoader {
    
    public let creator: LibraryCreator
    
    public init(creator: LibraryCreator) {
        self.creator = creator
    }
    
    public func load(path: String) -> [FiniteStateMachine] {
        // Ignore empty paths
        if (path.characters.count < 1) {
            return []
        }
        // Create the library resource.
        let lib: LibraryResource? = self.creator.open(path)
        if lib == nil {
            return []
        }
        // Load the machines
        let machines: [FiniteStateMachine] = self.getMachines(lib!, name: self.getDylibName(path))
        print("machines: \(machines.count)")
        return machines
    }
    
    private func getMachines(
        library: LibraryResource,
        name: String
    ) -> [FiniteStateMachine] {
        let result: (symbol: UnsafeMutablePointer<Void>, error: String?) =
            library.getSymbolPointer(
                "_TF8PingPong8machinesFT_C9Swift_FSM3FSM"
            )
        if (result.error != nil) {
            print(result.error!)
            return []
        }
        let op: COpaquePointer = COpaquePointer(result.symbol)
        let p: UnsafeMutablePointer<() -> Swift_FSM.FSM> = UnsafeMutablePointer<() -> Swift_FSM.FSM>(op)
        if (p == nil) {
            return []
        }
        return [p.memory()]
    }
    
    private func getDylibName(path: String) -> String {
        let name: String = path.substringWithRange(
            Range(
                start: self.getIndexOfCharacterAfterLastOccurenceOfLib(path),
                end: self.getIndexOfFirstCharacterBeforeExtension(path)
            )
        )
        return name
    }
    
    private func getIndexOfFirstCharacterBeforeExtension(
        path: String
    ) -> String.CharacterView.Index {
        var occurence: String.CharacterView.Index = path.characters.endIndex
        for index in path.characters.indices {
            if (path[index] == ".") {
                occurence = index
            }
        }
        return occurence
    }
    
    private func getIndexOfCharacterAfterLastOccurenceOfLib(
        path: String
    ) -> String.CharacterView.Index {
        var i: Int = 0
        var position: String.CharacterView.Index = path.characters.startIndex
        let ext: String.CharacterView.Index = self.getIndexOfFirstCharacterBeforeExtension(path)
        for index in path.characters.indices {
            if (path.characters.count - i < 3 || index >= ext) {
                return position
            }
            if ("lib" == path.substringWithRange(
                    Range(
                        start: index,
                        end: index.successor().successor().successor()
                    )
                )
            ) {
                position = index.successor().successor().successor()
            }
            i++
        }
        return position
    }
    
}
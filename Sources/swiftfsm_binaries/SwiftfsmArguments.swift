/*
 * SwiftfsmArguments.swift
 * swiftfsm_binaries
 *
 * Created by Callum McColl on 12/10/20.
 * Copyright © 2020 Callum McColl. All rights reserved.
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

import Gateways
import KripkeStructure
import ModelChecking
import Scheduling
import Verification
import MachineStructure
import ArgumentParser

struct SwiftfsmArguments: ParsableCommand {
    
    enum KripkeStructureFormats: String, CaseIterable, EnumerableFlag, ExpressibleByArgument {
        
        case graphviz
        case nusmv
        case tulip
        case gexf
        
        static func name(for value: KripkeStructureFormats) -> NameSpecification {
            switch value {
            case .graphviz:
                return [.short, .long]
            case .nusmv:
                return [.short, .long]
            case .tulip:
                return [.short, .long]
            case .gexf:
                return [.customShort("x"), .long]
            }
        }

        static func help(for value: KripkeStructureFormats) -> ArgumentHelp? {
            switch value {
            case .graphviz:
                return "GraphViz dot format. Outputs kripke_structure.gv."
            case .nusmv:
                return "NuSMV format. Outputs main.smv."
            case .tulip:
                return "Tulip format. Used by the Tulip graph visualiser. Outputs kripke_structure.tlp."
            case .gexf:
                return "Gexf format. Used by the Gephi graph visualiser. Outputs kripke_structure.gexf."
            }
        }
        
    }

    enum Schedulers: String, CaseIterable, EnumerableFlag, ExpressibleByArgument {

        case passiveRoundRobin
        case roundRobin
        case timeTriggered
        
        static func name(for value: Schedulers) -> NameSpecification {
            return [.short, .long]
        }

        static func help(for value: Schedulers) -> ArgumentHelp? {
            switch value {
            case .passiveRoundRobin:
                return ArgumentHelp(
                    "Passive Round-Robin",
                    discussion: "Takes a snapshot of the external variables before executing each entire schedule cycle. The snapshot is saved at the end of each schedule cycle, after all LLFSMs have executed a single ringlet."
                )
            case .roundRobin:
                return ArgumentHelp(
                    "Round-Robin",
                    discussion: "Takes a snapshot of the external variables before executing each ringlet in each LLFSM. The snapshot is saved after executing each ringlet in each LLFSM."
                )
            case .timeTriggered:
                return ArgumentHelp(
                    "Time-Triggered",
                    discussion: "Uses a time-triggered schedule map file to specify the schedule arrangment."
                )
            }
        }

    }
    
    @Flag(name: .shortAndLong, help: "Enable debugging.")
    var debug: Bool = false
    
    @Option(name: .shortAndLong, help: "Generate Kripke Structures in specific formats")
    var generateKripkeStructure: [KripkeStructureFormats] = []
    
    @Option(name: .shortAndLong, help: "Specify which scheduler to use. Defaults to a round-robin scheduler")
    var scheduler: Schedulers = .roundRobin
    
}

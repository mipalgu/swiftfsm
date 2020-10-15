/*
 * RunArguments.swift
 * swiftfsm_binaries
 *
 * Created by Callum McColl on 16/10/20.
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

import ArgumentParser

public struct RunArguments: ParsableArguments {
    
    public enum Schedulers: String, EnumerableFlag {

        case passiveRoundRobin
        case roundRobin
        
        public static func name(for value: Schedulers) -> NameSpecification {
            switch value {
            case .passiveRoundRobin:
                return [.customLong("prr", withSingleDash: true), .customLong("passive-round-robin")]
            case .roundRobin:
                return [.customLong("rr", withSingleDash: true), .customLong("round-robin")]
            }
        }

        public static func help(for value: Schedulers) -> ArgumentHelp? {
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
            }
        }

    }
    
    @Flag(name: .shortAndLong, help: "Enable debugging.")
    public var debug: Bool = false
    
    //@Flag(help: "Specify which scheduler to use.", transform: Schedulers.init)
    @Flag(exclusivity: FlagExclusivity.exclusive, help: "Specify which scheduler to use.")
    public var scheduler: Schedulers = .roundRobin
    
    @Option(name: .customShort("S"), help: "Specify a dispatch table to use instead of a standard scheduler.")
    public var dispatchTable: String?
    
    public init() {}
    
}

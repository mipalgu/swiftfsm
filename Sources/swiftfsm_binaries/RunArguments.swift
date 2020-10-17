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
    
    public enum Schedulers: RawRepresentable, ExpressibleByArgument {

        case passiveRoundRobin
        case roundRobin
        case timeTriggered(dispatchTable: String)
        
        public var defaultValueDescription: String {
            switch self {
            case .passiveRoundRobin:
                return "passive-round-robin"
            case .roundRobin:
                return "round-robin"
            case .timeTriggered:
                return "<file.table>"
            }
        }
        
        public static var allValueStrings: [String] {
            return ["round-robin", "passive-round-robin", "<file.table>"]
        }
        
        public var rawValue: String {
            switch self {
            case .roundRobin:
                return "round-robin"
            case .passiveRoundRobin:
                return "passive-round-robin"
            case .timeTriggered(let table):
                return table
            }
        }
        
        public init?(argument: String) {
            self.init(rawValue: argument)
        }
        
        public init?(rawValue: String) {
            switch rawValue {
            case "rr", "round-robin":
                self = .roundRobin
            case "prr", "passive-round-robin":
                self = .passiveRoundRobin
            default:
                self = .timeTriggered(dispatchTable: rawValue)
            }
        }

    }
    
    @Flag(name: .shortAndLong, help: "Enable debugging.")
    public var debug: Bool = false
    
    //@Flag(help: "Specify which scheduler to use.", transform: Schedulers.init)
    @Option(
        name: [.short, .long],
        help: ArgumentHelp(
            "Specify which scheduler to use.",
            discussion: """
                You may specify a standard scheduler or a dispatch table file.
                Standard schedulers:
                    round-robin: Takes a snapshot of the external variables before
                        executing each ringlet in each LLFSM. The snapshot is saved
                        after executing each ringlet in each LLFSM.
                    passive-round-robin: Takes a snapshot of the external variables
                        before executing each entire schedule cycle. The snapshot is
                        saved at the end of each schedule cycle, after all LLFSMS
                        have executed a single ringlet.
                Dispatch table file format:
                    The dispatch table file format allows specifying a parallal
                    time-triggered schedule. The dispatch table consists of
                    groups of machines in timeslots which execute sequentially.
                    Each group executes in parallel to the others. Each timeslot
                    has the following format:
                        <offset-start-time> <run-time> <machine>
                    where <offset-start-time> is the time offset from the start
                    of the schedule cycle and dictates when the machine should
                    start executing. An offset of 0 indicates that the machine
                    should start executing at the beginning of a schedule cycle.
                    The <run-time> field indicates how much time the
                    machine has to execute. The worst-cast execution time of the
                    machine should not exceed this value. The <machine> field
                    represents the name of the machine in the namespace. You
                    can fetch the names of all the machines in the arrangement
                    by executing `swiftfsm show-machines <directory.arrangement>`.
                    A group consists of several lines of timeslot:
                        <timeslot1>
                        <timeslot2>
                        <timeslot3>
                    and each group is separated by a blank line:
                        <timeslot1>
                        <timeslot2>
                        <timeslot3>

                        <timeslot4>
                        <timeslot5>
                        <timeslot6>
                    In this example, timeslots 1-3 are executed in parallel to
                    timeslots 4-6.
                """,
            valueName: "scheduler|<file.table>"
        )
    )
    public var scheduler: Schedulers = .roundRobin
    
    public init() {}
    
}

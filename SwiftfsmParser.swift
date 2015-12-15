/*
 * SwiftfsmParser.swift
 * swiftfsm
 *
 * Created by Callum McColl on 15/12/2015.
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

public class SwiftfsmParser: HelpableParser {
    
    public var helpText: String {
        var str: String = "OVERVIEW: A Finite State Machine Scheduler Written in Swift\n\n"
        str += "USAGE: swiftfsm [options] machine_path ...\n\n"
        str += "OPTIONS:\n"
        str += "\t-c, --clfsm\tSpecifies that this is a machine that has been built using the CLFSM specification.\n"
        str += "\t-d, --debug\tEnables debugging.\n"
        str += "\t-h, --help\tPrint this help message.\n"
        str += "\t-k, --kripke [-r|--run]\n"
        str += "\t\t\tGenerate the Kripke Structure for the machine.\n"
        str += "\t\t\tNote: Optionally specify -r or --run to schedule the machine to run as well as generate the kripke structure.\n"
        str += "\t-n, --name <value>\n"
        str += "\t\t\tSpecify a name for the machine.\n"
        str += "\n"
        return str
    }
    
    public func parse(var words: [String]) -> [Task] {
        var tasks: [Task] = []
        var t: Task = Task()
        // Keep looping while we still have input
        while (false == words.isEmpty) {
            t = self.handleNextFlag(t, words: &words)
            words.removeFirst()
            if (true == t.printHelpText) {
                return [t]
            }
            if (nil == t.path) {
                continue
            }
            tasks.append(t)
            t = Task()
        }
        return tasks
    }
    
    private func handleNextFlag(var t: Task, inout words: [String]) -> Task {
        switch (words.first!) {
        case "-h, --help":
            t = Task()
            t.printHelpText = true
            return t
        case "-c", "--clfsm":
            t.isClfsmMachine = true
        case "-d", "--debug":
            t.enableDebugging = true
        case "-k", "--kripke":
            t.generateKripkeStructure = true
            t.addToScheduler = false
            if (words.count < 2) {
                break
            }
            if ("-r" != words[1] && "--run" != words[1]) {
                break
            }
            t.addToScheduler = true
            words.removeFirst()
        case "-n", "--name":
            if (words.count < 2) {
                break
            }
            words.removeFirst()
            t.name = words.first!
        default:
            t.path = words.first!
            if (nil == t.name) {
                t.name = t.path
            }
        }
        return t
    }
    
}

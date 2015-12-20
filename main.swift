/*
 * main.swift
 * swiftfsm
 *
 * Created by Callum McColl on 14/08/2015.
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

import Darwin
import FSM

print("Hello, when I grow up, I will be a full-blown state machine scheduler!")
let parser: SwiftfsmParser = SwiftfsmParser()

if (Process.arguments.count < 2) {
    print(parser.helpText)
    exit(EXIT_SUCCESS)
}

var args: [String] = Process.arguments
args.removeFirst()

let tasks: [Task]
do {
    tasks = try parser.parse(args)
} catch(SwiftfsmErrors.UnknownFlag(let flag)) {
    print("Unknown Flag \(flag)")
    exit(EXIT_FAILURE)
}

if (true == tasks.isEmpty) {
    print("Unable to find a path to any machines.  Did you specify one?")
    exit(EXIT_FAILURE)
}

if let t:Task = tasks.filter({ true == $0.printHelpText }).first {
    print(parser.helpText)
    exit(EXIT_SUCCESS)
}

let loader: MachineLoader = DynamicLibraryMachineLoaderFactory().make()
var machines: [Machine] = []
var i: Int = 1
for t: Task in tasks {
    if (nil == t.path) {
        print("No path for \(nil == t.name ? "machine \(i)" : t.name!).")
        exit(EXIT_FAILURE)
    }
    let fsm: FiniteStateMachine? = loader.load(t.path!)
    if (nil == fsm) {
        print("Unable to load \(nil == t.name ? "machine \(i)" : t.name!) at \(t.path!).")
        exit(EXIT_FAILURE)
    }
    let m: Machine = SimpleMachine(
        name: nil == t.name ? "\(i)_t.path!" : t.name!,
        fsm: fsm!
    )
    if (true == t.generateKripkeStructure) {
        let generator: KripkeStructureGenerator =
            MachineKripkeStructureGenerator(
                generator: TeleportingTurtleGenerator(
                    extractor: MirrorPropertyExtractor()
                ),
                machine: m
            )
        let structure: KripkeStructureType = generator.generate()
        print(structure)
    }
    if (true == t.addToScheduler) {
        machines.append(m)
    }
    i++
}
let scheduler: RoundRobinScheduler = RoundRobinScheduler(machines: machines)
scheduler.run()

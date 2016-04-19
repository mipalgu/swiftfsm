/*
 * NuSMVKripkeStructureView2.swift 
 * swiftfsm 
 *
 * Created by Callum McColl on 14/04/2016.
 * Copyright © 2016 Callum McColl. All rights reserved.
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

import FSM

/*
 
MODULE main

VARS

machine-main-count : {
    0,
    1,
    2
}

pc : {
    machine-main-ping-R1,
    machine-main-pong-R1,
    machine-main-ping-R2,
    machine-main-pong-R2
}

INIT
    machine-main-count=0 & pc=machine-main-ping-R1

TRANS
case
machine-main-count=0 & pc=machine-main-ping-R1:
    next(machine-main-count)=1 & next(pc=machine-main-pong-R1;
machine-main-count=1 & pc=machine-main-pong-R1):
    next(pc=machine-main-ping-R1);
TRUE:
    next(pc)=machine-main-ping-R1;

*/

public class NuSMVKripkeStructureView2: KripkeStructureView {
    
    private let combinedModuleName: String

    private let debugPrinter: Printer

    private let ext: String

    private let factory: PrinterFactory

    private let parser: NuSMVKripkeStateParserType

    private let interpreter: NuSMVInterpreterType

    public init(
        factory: PrinterFactory,
        parser: NuSMVKripkeStateParserType,
        interpreter: NuSMVInterpreterType,
        ext: String = "nusmv",
        combinedModuleName: String = "main",
        debugPrinter: Printer = CommandLinePrinter(
            errorStream: StderrOutputStream(),
            messageStream: StdoutOutputStream()
        )
    ) {
        self.combinedModuleName = combinedModuleName
        self.debugPrinter = debugPrinter
        self.ext = ext
        self.factory = factory
        self.parser = parser
        self.interpreter = interpreter
    }

    public func make(structure: KripkeStructureType) {
        // Seperate the states into different modules and print the structures. 
        self.seperate(structure.states).forEach(processModule)
    }

    private func seperate(states: [KripkeState]) -> [String: [KripkeState]] {
        var modules: [String: [KripkeState]] = [self.combinedModuleName : states]
        for s: KripkeState in states {
            if (modules[s.machine.name] == nil) {
                modules[s.machine.name] = []
            }
            modules[s.machine.name]!.append(s)
        }
        // Only returned the combined module if there is only one machine.
        if (2 == modules.count) {
            return [self.combinedModuleName : modules[self.combinedModuleName]!]
        }
        return modules
    }

    private func processModule(module: String, _ states: [KripkeState]) {
        let data: NuSMVData? = self.parser.parse(module, states: states)
        if (nil == data) {
            self.debugPrinter.error(
                "Unable to Parse Kripke Structure for \(self.fileName(module))"
            )
            return
        }
        self.print(
            module,
            contents: self.interpreter.interpret(data!)
        )
    }

    private func fileName(module: String) -> String {
        return "\(module).\(self.ext)"
    }

    private func print(module: String, contents: String) {
        self.factory.make(self.fileName(module)).message(contents)
    }

}

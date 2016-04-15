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
    
    private let factory: PrinterFactory

    private let parser: NuSMVKripkeStructureParser

    private let interpreter: NuSMVInterpreter

    public func make(structure: KripkeStructureType) {
        // Seperate the states into different modules for each machine. 
        var states: [String: [KripkeState]] = ["main": structure.states]
        for s: KripkeState in structure.states {
            if (states[s.machine.name] == nil) {
                states[s.machine.name] = []
            }
            states[s.machine.name].append(s)
        }
        // Print each machines kripke structure.
        for (module: String, states: [KripkeState]) {
            self.print(module, self.parser.parse(module, states: states) >>- self.interpreter.interpret)
        }
    }

    private func print(module: String, contents: String?) {
        if (nil == contents) {
            return
        }
        self.factory.make(module).message(contents!)
    }

}

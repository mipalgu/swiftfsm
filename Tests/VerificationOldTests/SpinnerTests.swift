/*
 * SpinnerTests.swift 
 * tests 
 *
 * Created by Callum McColl on 24/09/2016.
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

import XCTest
@testable import Verification
/*
internal struct SimpleGlobals: ExternalVariables {

    var count: UInt8

    init() {
        self.count = 0
    }

    init(fromDictionary dictionary: [String: Any]) {
        self.count = dictionary["count"]! as! UInt8
    }

}

func ==(lhs: SimpleGlobals, rhs: SimpleGlobals) -> Bool {
    return lhs.count == rhs.count
}

internal class SimpleContainer<GV: ExternalVariables>: ExternalVariablesContainer, Snapshotable {
    
    typealias Class = GV

    public var val: GV

    public init(val: GV) {
        self.val = val
    }

    func saveSnapshot() {}

    func takeSnapshot() {}

}

public final class Counter: Variables {

    public var counter: UInt8 

    public init(counter: UInt8 = 0) {
        self.counter = counter
    }

    public final func clone() -> Counter {
        return Counter(counter: self.counter)
    }

}

internal final class ExitState: MiPalState {

    public override func main() {
        print("exit")
    }

    public final override func clone() -> ExitState {
        return ExitState(self.name, transitions: self.transitions)
    }

}

internal class CountingState: MiPalState {

    public var globals: SimpleContainer<SimpleGlobals>

    public var fsmVars: SimpleVariablesContainer<Counter>
    
    public var count: UInt8 {
        get {
            return self.globals.val.count
        } set {
            self.globals.val.count = newValue
        }
    }

    public var counter: UInt8 {
        get {
            return self.fsmVars.vars.counter
        } set {
            self.fsmVars.vars.counter = newValue
        }
    }

    public init(
        _ name: String,
        globals: SimpleContainer<SimpleGlobals>,
        fsmVars: SimpleVariablesContainer<Counter>
    ) {
        self.globals = globals
        self.fsmVars = fsmVars
        super.init(name, transitions: [])
    }

    public final override func clone() -> CountingState {
        let state = CountingState(
            self.name,
            globals: self.globals,
            fsmVars: self.fsmVars
        )
        state.transitions = self.transitions
        return state
    }

    public override func main() {
        print("count: \(self.count), counter: \(self.counter)")
        self.count = self.count &+ 1
        self.counter = self.counter &+ 1
    }

    public override func onExit() {
        print("count: \(self.count), counter: \(self.counter)")
        self.count = self.count &+ 1
        self.counter = self.counter &+ 1
    }

}

class SpinnerTests: XCTestCase {

    static var allTests: [(String, (SpinnerTests) -> () throws -> Void)] {
        return [
            ("test_print", test_print)
        ]
    }
    
    private var container: SimpleContainer<SimpleGlobals>!
    private var fsmVars: SimpleVariablesContainer<Counter>!
    private var fsm: AnyScheduleableFiniteStateMachine!

    override func setUp() {
        self.container = SimpleContainer(val: SimpleGlobals()) 
        self.fsmVars = SimpleVariablesContainer(vars: Counter())
        var state = CountingState(
            "countingState",
            globals: self.container,
            fsmVars: self.fsmVars
        )
        let ringlet = KripkeMiPalRinglet(
            externalVariables: [AnySnapshotController(self.container)],
            fsmVars: self.fsmVars,
            extractor: MirrorPropertyExtractor()
        )
        let exitState: MiPalState = ExitState("exit")
        let transition = Transition<MiPalState, MiPalState>(exitState) {
            let state = $0 as! CountingState
            return state.count >= 2
        }
        state.addTransition(transition)
        self.fsm = FSM(
            "test_fsm",
            initialState: state,
            externalVariables: [AnySnapshotController(self.container)],
            ringlet: ringlet,
            exitState: exitState
        )
    }

    func test_print() {
        //let _ = self.fsm.generate(machine: "test")
    }

}
*/

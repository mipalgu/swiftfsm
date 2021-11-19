/*
 * StackGateway.swift
 * Gateways
 *
 * Created by Callum McColl on 5/1/19.
 * Copyright © 2019 Callum McColl. All rights reserved.
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

#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

import IO
import swiftfsm

public final class StackGateway: ModifiableFSMGateway, ModifiableFSMGatewayDefaults, KripkeVariablesModifier {

    private let printer: Printer

    public let stackLimit: Int

    public var stacks: [FSM_ID: [PromiseData]] = [:]

    public var delegate: FSMGatewayDelegate?

    public var latestID: FSM_ID = 0

    public var fsms: [FSM_ID : FSMType] = [:]

    public var ids: [String: FSM_ID] = [:]
    
    public var validVars: [String: [Any]] {
        ["delegate": []]
    }

    public init(stackLimit: Int = 8192, printer: Printer = CommandLinePrinter(errorStream: StderrOutputStream(), messageStream: StdoutOutputStream(), warningStream: StdoutOutputStream())) {
        self.stackLimit = stackLimit
        self.printer = printer
    }

    public func setup(_ id: FSM_ID) {
        self.stacks[id] = []
    }

    public func invoke<R>(_ id: FSM_ID, withParameters parameters: [String: Any?], caller: FSM_ID) -> Promise<R> {
        guard let fsm = self.fsms[id]?.asParameterisedFiniteStateMachine else {
            self.error("Attempting to invoke FSM \(self.fsms[id]?.name ?? "with id \(id)") when it has not been scheduled.")
        }
        guard true == self.stacks[id]?.isEmpty else {
            self.error("Attempting to invoke FSM \(self.fsms[id]?.name ?? "with id \(id)") when it is already running.")
        }
        let promiseData = self.handleInvocation(id: id, fsm: fsm, withParameters: parameters)
        self.stacks[id]?.insert(promiseData, at: 0)
        self.delegate?.hasInvoked(inGateway: self, fsm: promiseData.fsm, withId: id, withParameters: parameters, caller: caller, storingResultsIn: promiseData)
        return promiseData.makePromise()
    }

    public func call<R>(_ id: FSM_ID, withParameters parameters: [String : Any?], caller: FSM_ID) -> Promise<R> {
        guard let fsm = self.fsms[id]?.asParameterisedFiniteStateMachine else {
            self.error("Attempting to call FSM \(self.fsms[id]?.name ?? "with id \(id)") when it has not been scheduled.")
        }
        guard let stackSize = self.stacks[caller]?.count else {
            self.error("Unable to fetch stack of fsm \(self.fsms[id]?.name ?? "with id \(id)")")
        }
        guard stackSize <= self.stackLimit else {
            self.error("Stack Overflow: Attempting to call FSM \(self.fsms[id]?.name ?? "with id \(id)") more times than the current stack limit (\(self.stackLimit)).")
        }
        let promiseData = self.handleInvocation(id: id, fsm: fsm, withParameters: parameters)
        self.stacks[caller]?.insert(promiseData, at: 0)
        self.delegate?.hasCalled(inGateway: self, fsm: promiseData.fsm, withId: id, withParameters: parameters, caller: caller, storingResultsIn: promiseData)
        return promiseData.makePromise()
    }

    fileprivate func handleInvocation(id: FSM_ID, fsm: AnyParameterisedFiniteStateMachine, withParameters parameters: [String: Any?]) -> PromiseData {
        return PromiseData(fsm: fsm.newMachine(parameters: parameters), hasFinished: false)
    }

    fileprivate func error(_ str: String) -> Never {
        self.printer.error(str: str)
        exit(EXIT_FAILURE)
    }

}

extension StackGateway: VerifiableGateway {

    public var gatewayData: [FSM_ID: [(PromiseData, PromiseData)]] {
        get {
            return self.stacks.mapValues { $0.map { ($0, $0.clone()) } }
        } set {
            self.stacks.removeAll()
            newValue.forEach {
                self.stacks[$0.key] = $0.value.map { (promiseData, clone) in
                    promiseData.fsm = clone.fsm
                    promiseData.hasFinished = clone.hasFinished
                    promiseData.result = clone.result
                    return promiseData
                }
            }
        }
    }

    public var verificationData: [FSM_ID: Int] {
        var dict: [FSM_ID: Int] = [:]
        dict.reserveCapacity(self.fsms.count)
        self.fsms.forEach {
            dict[$0.key] = self.stacks[$0.key]?.count ?? 0
        }
        return dict
    }

    public func finish(_ id: FSM_ID) {
        if self.stacks[id]?.isEmpty ?? true {
            return
        }
        self.stacks[id]?.first?.hasFinished = true
        self.stacks[id]?.removeFirst()
    }

}

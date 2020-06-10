/*
 * VerificationTokenExecuter.swift
 * Verification
 *
 * Created by Callum McColl on 10/9/18.
 * Copyright © 2018 Callum McColl. All rights reserved.
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
import Gateways
import KripkeStructure
import MachineStructure
import ModelChecking
import swiftfsm

public final class VerificationTokenExecuter<StateGenerator: KripkeStateGeneratorProtocol> {

    fileprivate let stateGenerator: StateGenerator
    fileprivate let worldCreator: WorldCreator

    fileprivate let recorder = MirrorKripkePropertiesRecorder()

    fileprivate var calls: [FSM_ID: [CallData]] = [:]

    public weak var delegate: VerificationTokenExecuterDelegate?

    public init(stateGenerator: StateGenerator, worldCreator: WorldCreator = WorldCreator()) {
        self.stateGenerator = stateGenerator
        self.worldCreator = worldCreator
    }

    public func execute(
        fsm: AnyScheduleableFiniteStateMachine,
        inTokens tokens: [[VerificationToken]],
        executing: Int,
        atOffset offset: Int,
        withExternals externals: [(AnySnapshotController, KripkeStatePropertyList)],
        andClock clock: UInt,
        clockConstraint: ClockConstraint,
        andParameterisedMachines parameterisedMachines: [FSM_ID: ParameterisedMachineData],
        andLastState lastState: KripkeState?,
        usingCallStack callStack: [FSM_ID: [CallData]],
        andPreviousResults results: [FSM_ID: Any?]
    ) -> ([KripkeState], [UInt], [(AnySnapshotController, KripkeStatePropertyList)], [FSM_ID: [CallData]], [FSM_ID: Any?]) {
        self.calls = [:]
        var results = results
        let token = tokens[executing][offset]
        let data = token.data!
        data.machine.clock.forcedRunningTime = clock
        data.machine.clock.lastClockValues = []
        var externals = externals
        let state = fsm.currentState.name
        let preWorld = self.worldCreator.createWorld(
            fromExternals: externals,
            andParameterisedMachines: parameterisedMachines,
            andTokens: tokens,
            andLastState: lastState,
            andExecuting: executing,
            andExecutingToken: offset,
            withState: state,
            usingCallStack: callStack,
            worldType: .beforeExecution
        )
        let clockName = self.clockName(forToken: tokens[executing][offset])
        let time = (lastState == nil ? 0 : self.timeSinceLastStart(in: tokens, executing: executing, offset: offset)) ?? 0
        let preState = self.stateGenerator.generateKripkeState(clockName: clockName, resetClock: token.data?.lastFSMStateName != token.data?.fsm.currentState.name, fromWorld: preWorld, constraint: nil, time: time, withLastState: lastState)
        var newCallStack: [FSM_ID: [CallData]] = callStack
        if false == (callStack[data.id]?.last?.inPlace ?? false) {
            fsm.next()
            fsm.externalVariables.forEach { external in
                for var (i, (e, _)) in externals.enumerated() where e.name == external.name {
                    e.val = external.val
                    externals[i] = (e, self.recorder.takeRecord(of: e.val))
                }
            }
            // Create a new call stack if we detect that the fsm has invoked or called another fsm.
            newCallStack = self.mergeStacks(callStack, self.calls)
            for id in self.calls.keys {
                results[id] = nil
            }
        } else if let callData = callStack[data.id]?.last {
            newCallStack[data.id] = Array((newCallStack[data.id] ?? []).dropLast()) + [CallData(data: callData.data, parameters: callData.parameters, promiseData: callData.promiseData, runs: callData.runs + 1)]
        }
        let newConstraint: ClockConstraint? = data.machine.clock.lastClockValues.isEmpty ? nil : clockConstraint
        //print("self.calls: \(self.calls)")
        let postWorld = self.worldCreator.createWorld(
            fromExternals: externals,
            andParameterisedMachines: parameterisedMachines,
            andTokens: tokens,
            andLastState: preState,
            andExecuting: executing,
            andExecutingToken: offset,
            withState: state,
            usingCallStack: newCallStack,
            worldType: .afterExecution
        )
        //let preConstraint = self.calculateConstraint(clock: clock, clockValuesDuringRun: clock)
        let postState = self.stateGenerator.generateKripkeState(clockName: clockName, resetClock: false, fromWorld: postWorld, constraint: newConstraint, time: tokens[executing][offset].timeData?.duration ?? 0, withLastState: preState)
        return ([preState, postState], data.machine.clock.lastClockValues, externals, newCallStack, results)
    }
    
    private func clockName(forToken token: VerificationToken) -> String {
        guard let data = token.data else {
            fatalError("Generating Kripke States for a skip verification token.")
        }
        return data.machine.name + "." + data.fsm.name + ".clock"
    }

    fileprivate func mergeStacks(_ lhs: [FSM_ID: [CallData]], _ rhs: [FSM_ID: [CallData]]) -> [FSM_ID: [CallData]] {
        var newStack: [FSM_ID: [CallData]] = lhs
        for (id, stack) in rhs {
            newStack[id] = (lhs[id] ?? []) + stack
        }
        return newStack
    }
    
    private func timeSinceLastStart(in tokens: [[VerificationToken]], executing: Int, offset: Int) -> UInt? {
        guard let currentOffset = tokens[executing][offset].timeData else {
            return nil
        }
        // Get the offset of the previous token in the same cycle.
        if offset > 0, let lastExecuted = tokens[executing][0..<offset].last(where: { nil != $0.data })?.timeData {
            return currentOffset.startTime - (lastExecuted.startTime + lastExecuted.duration)
        }
        // Get the offset of the last token in the previous executed cycle.
        if let lastExecuted = tokens[0..<executing].last(where: { nil != $0.first { nil != $0.data} })?.last(where: { nil != $0.data })?.timeData {
            return currentOffset.startTime - (lastExecuted.startTime + lastExecuted.duration)
        }
        // Wrap around if we are unable to get the last token from the previous executed cycle.
        let currentExecutingIndex = tokens.index(0, offsetBy: executing)
        if let firstExecutingIndex = tokens.firstIndex(where: { nil != $0.first { nil != $0.data } }),
            currentExecutingIndex == firstExecutingIndex,
            tokens.count > (firstExecutingIndex + 1),
            let lastExecuted = tokens[(executing)..<tokens.count].last(where: { nil != $0.first { nil != $0.data } })?.last(where: { nil != $0.data })?.timeData
        {
            return currentOffset.startTime + (lastExecuted.cycleLength - (lastExecuted.startTime + lastExecuted.duration))
        }
        return currentOffset.startTime
    }

}

extension VerificationTokenExecuter: FSMGatewayDelegate {


    public func hasCalled(inGateway gateway: ModifiableFSMGateway, fsm: AnyParameterisedFiniteStateMachine, withId id: FSM_ID, withParameters parameters: [String: Any], caller: FSM_ID, storingResultsIn promiseData: PromiseData) {
        guard let delegate = self.delegate else {
            fatalError("delegate has not been set.")
            return
        }
        guard let (name, _) = gateway.ids.first(where: { $1 == id }) else {
            fatalError("Unable to fetch fully qualified name from id.")
        }
        let data = delegate.scheduleInfo(of: id, caller: caller, inGateway: gateway)
        self.addCall(CallData(data: data, parameters: parameters, promiseData: promiseData, runs: 0))
    }

    public func hasInvoked(inGateway gateway: ModifiableFSMGateway, fsm: AnyParameterisedFiniteStateMachine, withId id: FSM_ID, withParameters parameters: [String: Any], caller: FSM_ID, storingResultsIn promiseData: PromiseData) {
        guard let delegate = self.delegate else {
            fatalError("delegate has not been set.")
            return
        }
        guard let (name, _) = gateway.ids.first(where: { $1 == id }) else {
            fatalError("Unable to fetch fully qualified name from id.")
        }
        let data = delegate.scheduleInfo(of: id, caller: caller, inGateway: gateway)
        self.addCall(CallData(data: data, parameters: parameters, promiseData: promiseData, runs: 0))
    }

    fileprivate func addCall(_ data: CallData) {
        if nil == self.calls[data.id] {
            self.calls[data.id] = [data]
            return
        }
        self.calls[data.id]?.append(data)
    }

}

/*
 * SnapshotSectionVariations.swift
 * Verification
 *
 * Created by Callum McColl on 17/2/21.
 * Copyright © 2021 Callum McColl. All rights reserved.
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

import swiftfsm
import Gateways
import Timers
import KripkeStructure

/// Represents all possible execution paths through a single external variable
/// snapshot section in the scheduler.
///
/// The snapshot section represents the exection of all fsms within the
/// scheduler that are between the reading of a snapshot for the external
/// variables, and the saving of the external variable snapshot after the fsms
/// have finished executing.
///
/// Since swiftfsm provides the ability to specify a set of fsms that take part
/// in a single snapshot section, this struct represents all possible pathways
/// through the snapshot section.
struct SnapshotSectionVariations {
   
    var sections: [SnapshotSection]
    
    init<Gateway: ModifiableFSMGateway, Timer: Clock>(fsms: [CallChain], gateway: Gateway, timer: Timer, startingTime: UInt) {
        let sensorCombinations = Combinations(flatten: fsms.map {
            Combinations(flatten: $0.fsm.snapshotSensors.map { Combinations(snapshotController: $0) })
        })
        let sections = sensorCombinations.flatMap { (combinations) -> [[ConditionalRinglet]] in
            func process(path: [ConditionalRinglet], index: Int) -> [[ConditionalRinglet]] {
                if index >= combinations.count || index >= fsms.count {
                    return [path]
                }
                let clone = fsms[index].fsm.clone()
                clone.snapshotSensorValues = combinations[index]
                let ringlets = TimeAwareRinglets(fsm: clone, gateway: gateway, timer: timer, startingTime: startingTime).ringlets
                return ringlets.flatMap {
                    process(path: path + [$0], index: index + 1)
                }
            }
            var arr: [ConditionalRinglet] = []
            arr.reserveCapacity(min(fsms.count, combinations.count))
            return process(path: arr, index: 0)
        }
        self.init(sections: sections.map {
            SnapshotSection(ringlets: zip(fsms, $0).map {
                CallAwareRinglet(callChain: CallChain(root: $0.root, calls: $0.calls), ringlet: $1)
            })
        })
    }
    
    init(sections: [SnapshotSection]) {
        self.sections = sections
    }
    
}

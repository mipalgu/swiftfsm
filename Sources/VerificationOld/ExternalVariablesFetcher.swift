/*
 * ExternalVariablesFetcher.swift
 * Verification
 *
 * Created by Callum McColl on 18/3/19.
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

import KripkeStructure
import FSM

public final class ExternalVariablesFetcher {
    
    private let extractor = ExternalsSpinnerDataExtractor(converter: KripkeStatePropertySpinnerConverter(), extractor: MirrorKripkePropertiesRecorder())
    
    public init() {}

    public func createExternals(fromTokens tokens: [[VerificationToken]]) -> [String: (AnySnapshotController, KripkeStatePropertyList)] {
        let allExternalsData = self.fetchUniqueExternalsData(fromTokens: tokens)
        var d = [String: (AnySnapshotController, KripkeStatePropertyList)](minimumCapacity: allExternalsData.count)
        allExternalsData.forEach {
            d[$0.externalVariables.name] = ($0.externalVariables, $0.defaultValues)
        }
        return d
    }

    public func fetchUniqueExternalsData(fromTokens tokens: [[VerificationToken]]) -> [ExternalVariablesVerificationData] {
        var hashTable: Set<String> = []
        var externals: [ExternalVariablesVerificationData] = []
        for tokens in tokens {
            for token in tokens where token.data != nil {
                guard let data = token.data else {
                    continue
                }
                let allSensors = data.externalVariables + data.sensors
                let snapshotSensors = Set(data.fsm.snapshotSensors.lazy.map { $0.name })
                for external in allSensors.lazy.filter({ snapshotSensors.contains($0.externalVariables.name) }) {
                    if hashTable.contains(external.externalVariables.name) {
                        continue
                    }
                    externals.append(external)
                    hashTable.insert(external.externalVariables.name)
                }
                let allExternals = allSensors + data.actuators
                for external in allExternals.lazy.filter({ !snapshotSensors.contains($0.externalVariables.name) }) {
                    if hashTable.contains(external.externalVariables.name) {
                        continue
                    }
                    hashTable.insert(external.externalVariables.name)
                    let (props, spinners) = self.extractor.extract(actuators: external.externalVariables)
                    externals.append(
                        ExternalVariablesVerificationData(
                            externalVariables: external.externalVariables,
                            defaultValues: props,
                            spinners: spinners
                        )
                    )
                }
            }
        }
        return externals
    }

    public func mergeExternals(_ externals: [(AnySnapshotController, KripkeStatePropertyList)], with dict: [String: (AnySnapshotController, KripkeStatePropertyList)]) -> [(AnySnapshotController, KripkeStatePropertyList)] {
        var dict = dict
        for (external, ps) in externals {
            dict[external.name] = (external, ps)
        }
        return Array(dict.values)
    }

}

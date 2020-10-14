/*
 * ExternalsSpinnerDataExtractor.swift 
 * FSM 
 *
 * Created by Callum McColl on 27/09/2016.
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
import KripkeStructure
import ModelChecking

/**
 *  Provides a way to extract the variables from a `ExternalVariables` and create
 *  `Spinners.Spinner`s for each variables.
 */
public class ExternalsSpinnerDataExtractor<
    E: ExternalsPropertyExtractor,
    KSPC: KripkeStatePropertySpinnerConverterType
>: ExternalsSpinnerDataExtractorType {

    private let converter: KSPC

    private let extractor: E

    /**
     *  Create a new `ExternalsSpinnerDataExtractor`.
     *
     *  - Parameter converter: Used to convert a `KripkeStateProperty` to a
     *  `Spinners.Spinner`.
     *
     *  - Parameter extractor: Used to extract the values for the
     *  `ExternalVariables`.
     */
    public init(converter: KSPC, extractor: E) {
        self.converter = converter
        self.extractor = extractor
    }

    /**
     *  Create `Spinners.Spinner`s for the `ExternalVariables`.
     *
     *  - Parameter externalVariables: The `ExternalVariables`.
     *
     *  - Returns: A tuple where the first element is a dictionary where the
     *  keys represents the label of each variables within the
     *  `ExternalVariables` and the value represents the starting value for each
     *  variables `Spinners.Spinner`.  The second element is a dictionary where
     *  the keys represent the label of each variable within the
     *  `ExternalVariables` and the values are the `Spinners.Spinner` for each
     *  variable.
     */
    public func extract(
        externalVariables: AnySnapshotController
    ) -> (
        KripkeStatePropertyList,
        [String: (Any) -> Any?]
    ) {
        // Get Global Properties Info
        let list = self.extractor.extract(externalVariables: externalVariables)
        var spinners: [String: (Any) -> Any?] = [:]
        list.forEach {
            spinners[$0] = self.converter.convert(from: $1).1
        }
        return (list, spinners)
    }
    
    public func extract(
        actuators: AnySnapshotController
    ) -> (
        KripkeStatePropertyList,
        [String: (Any) -> Any?]
    ) {
        // Get Global Properties Info
        let list = self.extractor.extract(externalVariables: actuators)
        var spinners: [String: (Any) -> Any?] = [:]
        list.forEach {
            spinners[$0] = self.converter.emptySpinner(from: $1).1
        }
        return (list, spinners)
    }

}

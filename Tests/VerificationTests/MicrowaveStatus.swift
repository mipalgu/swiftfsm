/*
 * MicrowaveStatus.swift
 * ExternalVariables
 *
 * Created by Callum McColl on 9/9/18.
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
import CTests

//swiftlint:disable superfluous_disable_command
//swiftlint:disable type_body_length
//swiftlint:disable function_body_length
//swiftlint:disable file_length
//swiftlint:disable line_length
//swiftlint:disable identifier_name

#if canImport(swiftfsm)
import swiftfsm
#endif

/**
 * Contains properties of the one minute microwave.
 */
public struct MicrowaveStatus {

    public var _raw: wb_microwave_status

    public var timeLeft: Bool {
        get {
            return self._raw.timeLeft
        } set {
            self._raw.timeLeft = newValue
        }
    }

    public var doorOpen: Bool {
        get {
            return self._raw.doorOpen
        } set {
            self._raw.doorOpen = newValue
        }
    }

    public var buttonPushed: Bool {
        get {
            return self._raw.buttonPushed
        } set {
            self._raw.buttonPushed = newValue
        }
    }

    public var computedVars: [String: Any] {
        return [
            "timeLeft": self._raw.timeLeft,
            "doorOpen": self._raw.doorOpen,
            "buttonPushed": self._raw.buttonPushed
        ]
    }

    public var manipulators: [String: (Any) -> Any] {
        return [:]
    }

    public var validVars: [String: [Any]] {
        return ["_raw": []]
    }

    /**
     * Create a new `wb_microwave_status`.
     */
    public init(timeLeft: Bool = true, doorOpen: Bool = true, buttonPushed: Bool = true) {
        self._raw = wb_microwave_status()
        self.timeLeft = timeLeft
        self.doorOpen = doorOpen
        self.buttonPushed = buttonPushed
    }

    /**
     * Create a new `wb_microwave_status`.
     */
    public init(_ rawValue: wb_microwave_status) {
        self._raw = rawValue
    }

    /**
     * Create a `wb_microwave_status` from a dictionary.
     */
    public init(fromDictionary dictionary: [String: Any]) {
        self.init()
        guard
            let timeLeft = dictionary["timeLeft"] as? Bool,
            let doorOpen = dictionary["doorOpen"] as? Bool,
            let buttonPushed = dictionary["buttonPushed"] as? Bool
        else {
            fatalError("Unable to convert \(dictionary) to wb_microwave_status.")
        }
        self.timeLeft = timeLeft
        self.doorOpen = doorOpen
        self.buttonPushed = buttonPushed
    }

}

extension MicrowaveStatus: CustomStringConvertible {

    /**
     * Convert to a description String.
     */
    public var description: String {
        var descString = ""
        descString += "timeLeft=\(self.timeLeft)"
        descString += ", "
        descString += "doorOpen=\(self.doorOpen)"
        descString += ", "
        descString += "buttonPushed=\(self.buttonPushed)"
        return descString
    }

}

extension MicrowaveStatus: Equatable {}

public func == (lhs: MicrowaveStatus, rhs: MicrowaveStatus) -> Bool {
    return lhs.timeLeft == rhs.timeLeft
        && lhs.doorOpen == rhs.doorOpen
        && lhs.buttonPushed == rhs.buttonPushed
}

extension wb_microwave_status: Equatable {}

public func == (lhs: wb_microwave_status, rhs: wb_microwave_status) -> Bool {
    return MicrowaveStatus(lhs) == MicrowaveStatus(rhs)
}

#if canImport(swiftfsm)
extension MicrowaveStatus: ExternalVariables, KripkeVariablesModifier {}
#endif

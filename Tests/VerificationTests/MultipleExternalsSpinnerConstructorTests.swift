/*
 * MultipleExternalsSpinnerConstructorTests.swift
 * FSMTests
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

@testable import Verification
import swiftfsm
import ExternalVariables
import KripkeStructure
import CTests

import XCTest

//swiftlint:disable line_length
class MultipleExternalsSpinnerConstructorTests: XCTestCase {

    static var allTests: [(String, (MultipleExternalsSpinnerConstructorTests) -> () throws -> Void)] {
        return [
            ("test_canSpinMicrowaveVariables", test_canSpinMicrowaveVariables),
            ("test_canSpinMutlipleMicrowaveVariables", test_canSpinMutlipleMicrowaveVariables),
            ("test_canSpinButtonExternalVariables", test_canSpinButtonExternalVariables),
            ("test_canSpinMultupleButtonExternalVariables", test_canSpinMultupleButtonExternalVariables),
            ("test_canSpinNoVariables", test_canSpinNoVariables),
            ("test_canSpinMultipleMicrowaveStatusAndButton", test_canSpinMultipleMicrowaveStatusAndButton),
            ("test_canSpinMicrowaveStatusAndButton", test_canSpinMicrowaveStatusAndButton)
        ]
    }

    fileprivate var constructor: MultipleExternalsSpinnerConstructor<ExternalsSpinnerConstructor<SpinnerRunner>>!
    fileprivate var extractor: ExternalsSpinnerDataExtractor<MirrorKripkePropertiesRecorder, KripkeStatePropertySpinnerConverter>!

    override func setUp() {
        self.constructor = MultipleExternalsSpinnerConstructor(
            constructor: ExternalsSpinnerConstructor(
                runner: SpinnerRunner()
            )
        )
        self.extractor = ExternalsSpinnerDataExtractor(
            converter: KripkeStatePropertySpinnerConverter(),
            extractor: MirrorKripkePropertiesRecorder()
        )
    }
    
    func test_canSpinBoolVariables() {
        let timeLeft = AnySnapshotController(
            InMemoryContainer<Bool>(name: "Bool", initialValue: false)
        )
        let expected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [timeLeft], against: [expected])
    }

    func test_canSpinMutlipleBoolVariables() {
        let timeLeft = AnySnapshotController(
            InMemoryContainer<Bool>(name: "timeLeft", initialValue: false)
        )
        let doorOpen = AnySnapshotController(
            InMemoryContainer<Bool>(name: "doorOpen", initialValue: false)
        )
        let buttonPushed = AnySnapshotController(
            InMemoryContainer<Bool>(name: "buttonPushed", initialValue: false)
        )
        let expected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["value": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [timeLeft, doorOpen, buttonPushed], against: [expected, expected, expected])
    }

    func test_canSpinMicrowaveVariables() {
        let microwave_status = AnySnapshotController(
            InMemoryContainer<MicrowaveStatus>(name: "microwave_status", initialValue: MicrowaveStatus())
        )
        let expected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [microwave_status], against: [expected])
    }

    func test_canSpinMutlipleMicrowaveVariables() {
        let microwave_status = AnySnapshotController(
            InMemoryContainer<MicrowaveStatus>(name: "microwave_status", initialValue: MicrowaveStatus())
        )
        let expected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [microwave_status, microwave_status], against: [expected, expected])
    }

    func test_canSpinButtonExternalVariables() {
        let button = AnySnapshotController(ButtonSnapshotController())
        let expected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [button], against: [expected])
    }

    func test_canSpinMultupleButtonExternalVariables() {
        let button = AnySnapshotController(ButtonSnapshotController())
        let expected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [button, button], against: [expected, expected])
    }

    func test_canSpinMicrowaveStatusAndButton() {
        let microwave_status = AnySnapshotController(
            InMemoryContainer<MicrowaveStatus>(name: "microwave_status", initialValue: MicrowaveStatus())
        )
        let microwaveExpected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)])
        ]
        let button = AnySnapshotController(ButtonSnapshotController())
        let buttonExpected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [microwave_status, button], against: [microwaveExpected, buttonExpected])
    }

    func test_canSpinMultipleMicrowaveStatusAndButton() {
        let microwave_status = AnySnapshotController(
            InMemoryContainer<MicrowaveStatus>(name: "microwave_status", initialValue: MicrowaveStatus())
        )
        let microwaveExpected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: false), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: false), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)]),
            KripkeStatePropertyList(["buttonPushed": KripkeStateProperty(type: .Bool, value: true), "doorOpen": KripkeStateProperty(type: .Bool, value: true), "timeLeft": KripkeStateProperty(type: .Bool, value: true)])
        ]
        let button = AnySnapshotController(ButtonSnapshotController())
        let buttonExpected: [KripkeStatePropertyList] = [
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: false)]),
            KripkeStatePropertyList(["button": KripkeStateProperty(type: .Bool, value: true)])
        ]
        self.check(externals: [microwave_status, button, microwave_status, microwave_status, button, button, button], against: [microwaveExpected, buttonExpected, microwaveExpected, microwaveExpected, buttonExpected, buttonExpected, buttonExpected])
    }

    func test_canSpinNoVariables() {
        self.check(externals: [], against: [])
    }

    fileprivate func check(externals: [AnySnapshotController], against expected: [[KripkeStatePropertyList]]) {
        if externals.count != expected.count {
            XCTFail("externals.count != expected.count")
            return
        }
        let spinner = self.makeSpinner(externals)
        if true == expected.isEmpty {
            guard let data = spinner() else {
                XCTFail("First spinner value is nil.")
                return
            }
            XCTAssertTrue(data.isEmpty)
            XCTAssertNil(spinner())
            return
        }
        var seen: Set<KripkeStatePropertyList> = []
        while let data = spinner() {
            XCTAssertEqual(data.count, expected.count)
            if data.count != expected.count {
                return
            }
            // Check to see if spinner spits out the same configuration more than once.
            let combined = self.combine(properties: data.map { $1 })
            if true == seen.contains(combined) {
                XCTFail("spinner returns a duplicate configuration: \(combined)")
                return
            }
            seen.insert(combined)
            for (d, es) in zip(data, expected) {
                guard let expectedItem = es.first(where: { $0 == d.1 }) else {
                    XCTFail("spinner returns unexpected result: \(d.1)")
                    return
                }
                XCTAssertEqual(expectedItem, d.1)
            }
        }
        let expectedCount = expected.reduce(1) { $0 * $1.count }
        XCTAssertEqual(seen.count, expectedCount, "spinner did not generate all possible expected configurations")
    }

    fileprivate func combine(properties: [KripkeStatePropertyList]) -> KripkeStatePropertyList {
        var d: [String: KripkeStateProperty] = [:]
        for (index, p) in properties.enumerated() {
            d["\(index)"] = KripkeStateProperty(type: .Compound(p), value: [:])
        }
        return KripkeStatePropertyList(d)
    }

    fileprivate func makeSpinner(_ externalVariables: [AnySnapshotController]) -> () -> [(AnySnapshotController, KripkeStatePropertyList)]? {
        let externals = externalVariables.map { (externals: AnySnapshotController) -> ExternalVariablesVerificationData in
            let (defaultValues, spinners) = self.extractor.extract(externalVariables: externals)
            return ExternalVariablesVerificationData(
                externalVariables: externals,
                defaultValues: defaultValues,
                spinners: spinners
            )
        }
        return self.constructor.makeSpinner(forExternals: externals)
    }

}

private struct ButtonExternalVariables: ExternalVariables {

    var button: Bool

    init(button: Bool = false) {
        self.button = button
    }

    init(fromDictionary dictionary: [String: Any]) {
        guard let button = dictionary["button"] as? Bool else {
            fatalError("Unable to convert dictioanry to ButtonExternalVariables")
        }
        self.button = button
    }

}

private class ButtonSnapshotController: Identifiable, ExternalVariablesContainer, Snapshotable {

    let name: String = "ButtonSnapshotController"

    var val: ButtonExternalVariables = ButtonExternalVariables()

    func takeSnapshot() {}

    func saveSnapshot() {}

}

extension ButtonExternalVariables: Equatable {}

private func == (lhs: ButtonExternalVariables, rhs: ButtonExternalVariables) -> Bool {
    return lhs.button == rhs.button
}

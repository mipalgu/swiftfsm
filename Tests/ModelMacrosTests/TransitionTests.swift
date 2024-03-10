import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ModelMacros)
@testable import ModelMacros
#endif

final class TransitionTests: XCTestCase {

    func test_generatesCorrectCode() throws {
        #if canImport(ModelMacros)
        assertMacroExpansion(
            "let abcd = #transition(to: \\.$pong)",
            expandedSource: "let abcd = Transition(to: \\.$pong)",
            macros: ["transition": Transition.self]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


}

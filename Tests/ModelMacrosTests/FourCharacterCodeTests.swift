import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ModelMacros)
@testable import ModelMacros
#endif

final class FourCharacterCodeTests: XCTestCase {

    func test_generatesCorrectCode() throws {
        #if canImport(ModelMacros)
        assertMacroExpansion(
            "let abcd = #fourCharacterCode(\"ABCD\")",
            expandedSource: "let abcd = 1094861636 as UInt32",
            macros: ["fourCharacterCode": FourCharacterCode.self]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


}

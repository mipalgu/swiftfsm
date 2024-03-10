import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ModelMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [FourCharacterCode.self]
}

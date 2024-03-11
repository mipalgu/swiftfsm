import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct State: AccessorMacro {
    

    /// Expand a macro described by the given attribute to
    /// produce accessors for the given declaration to which
    /// the attribute is attached.
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw CustomError.message("The State macro can only be attached to variable declarations.")
        }
        guard let state = StateConstruct(varDecl: varDecl) else {
            throw CustomError.message("Malformed @State attribute.")
        }
        return [
            """
            get { \(raw: state.typeName)() }
            """
        ]
    }

}

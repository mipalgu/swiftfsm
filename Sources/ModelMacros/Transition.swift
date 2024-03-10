import SwiftSyntax
import SwiftSyntaxMacros

public struct Transition: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            let argument = node.argumentList.first?.expression,
            let expression = argument.as(KeyPathExprSyntax.self)
        else {
            throw CustomError.message("Need target.")
        }
        let components = expression.components.description
        return "\(raw: components)"
    }

}

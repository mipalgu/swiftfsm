import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private struct StateIdentifier {

    var id: Int

    var name: String

    var identifier: String

    var typeName: String {
        name.capitalized + "State"
    }

    init(id: Int, name: String, identifier: String) {
        self.id = id
        self.name = name
        self.identifier = identifier
    }

    init?(memberBlockItem: MemberBlockItemSyntax) {
        guard let varDecl = memberBlockItem.decl.as(VariableDeclSyntax.self) else {
            return nil
        }
        self.init(varDecl: varDecl)
    }

    init?(varDecl: VariableDeclSyntax) {
        guard
            let stateAttribute = varDecl
                .attributes
                .lazy
                .compactMap({ $0.as(AttributeSyntax.self) })
                .first(where: { "\($0.attributeName)" == "State" }),
            let arguments = stateAttribute.arguments?.as(LabeledExprListSyntax.self)
        else {
            return nil
        }
        let potentialName = arguments
            .first(where: { $0.label?.description.trimmingCharacters(in: .whitespacesAndNewlines) == "name" })?
            .expression.as(StringLiteralExprSyntax.self)?
            .description
        let name = potentialName.map { String($0.dropFirst().dropLast()) }
            ?? varDecl.bindings.description.capitalized
        self.init(id: -1, name: name, identifier: varDecl.bindings.description)
    }

    // func structDecl(modifiers: DeclModifierListSyntax = []) -> StructDeclSyntax {
    //     StructDeclSyntax(
    //         modifiers: modifiers,
    //         structKeyword: .keyword(.struct),
    //         name: .identifier(name + "State"),
    //         genericParameterClause: nil,
    //         inheritanceClause: nil,
    //         genericWhereClause: nil,
    //         memberBlock: MemberBlockSyntax(
    //             members: []
    //         )
    //     )
    // }

}

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
        guard let state = StateIdentifier(varDecl: varDecl) else {
            throw CustomError.message("Malformed @State attribute.")
        }
        return [
            """
            get { \(raw: state.typeName)() }
            """
        ]
    }

}

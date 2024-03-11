import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct StateConstruct {

    var id: Int

    var name: String

    var identifier: String

    var onEntry: String

    var main: String
    
    var onExit: String

    var onSuspend: String

    var onResume: String

    var typeName: String {
        name.capitalized + "State"
    }

    init(
        id: Int,
        name: String,
        identifier: String,
        onEntry: String = "",
        main: String = "",
        onExit: String = "",
        onSuspend: String = "",
        onResume: String = ""
    ) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.onEntry = onEntry
        self.main = main
        self.onExit = onExit
        self.onSuspend = onSuspend
        self.onResume = onResume
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

    func structDecl(modifiers: DeclModifierListSyntax = []) -> StructDeclSyntax {
        StructDeclSyntax(
            modifiers: modifiers,
            structKeyword: .keyword(.struct),
            name: .identifier(name + "State"),
            genericParameterClause: nil,
            inheritanceClause: nil,
            genericWhereClause: nil,
            memberBlock: MemberBlockSyntax(
                members: []
            )
        )
    }

}

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct StateConstruct {

    var id: Int

    var name: String

    var identifier: String

    var context: (initialise: String, type: String)

    var environment: Set<String>

    var onEntry: String

    var main: String
    
    var onExit: String

    var onSuspend: String

    var onResume: String

    var typeName: String {
        name + "State"
    }

    init(
        id: Int,
        name: String,
        identifier: String,
        context: (initialise: String, type: String) = ("EmptyDataStructure()", "EmptyDataStructure"),
        environment: Set<String> = [],
        onEntry: String = "",
        main: String = "",
        onExit: String = "",
        onSuspend: String = "",
        onResume: String = ""
    ) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.context = context
        self.environment = environment
        self.onEntry = onEntry
        self.main = main
        self.onExit = onExit
        self.onSuspend = onSuspend
        self.onResume = onResume
    }

    init(memberBlockItem: MemberBlockItemSyntax) throws {
        guard let varDecl = memberBlockItem.decl.as(VariableDeclSyntax.self) else {
            throw CustomError.message("Cannot parse state from member block item.")
        }
        try self.init(varDecl: varDecl)
    }

    init(varDecl: VariableDeclSyntax) throws {
        guard
            let stateAttribute = varDecl
                .attributes
                .lazy
                .compactMap({ $0.as(AttributeSyntax.self) })
                .first(where: { "\($0.attributeName)" == "State" }),
            let arguments = stateAttribute.arguments?.as(LabeledExprListSyntax.self)
        else {
            throw CustomError.message("Unable to fetch arguments from attribute.")
        }
        let label = varDecl.bindings.description
        var potentialName: String?
        var (initialContext, initialContextType) = ("EmptyDataStructure()", "EmptyDataStructure")
        var environment: Set<String> = []
        var onEntry = ""
        var main = ""
        var onExit = ""
        var onSuspend = ""
        var onResume = ""
        var usesSeen = false
        var params: Set<String> = Set()
        for argument in arguments {
            let label = argument.label?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !usesSeen && label.isEmpty {
                throw CustomError.message("Missing label in state definition.")
            }
            if !label.isEmpty {
                guard !params.contains(label) else {
                    throw CustomError.message("Duplicate " + label + " parameter in state definition.")
                }
                params.insert(label)
                usesSeen = label == "uses"
            }
            switch label {
            case "name":
                potentialName = (argument.expression.as(StringLiteralExprSyntax.self)?.description).map {
                    String($0.dropFirst().dropLast())
                }
            case "initialContext":
                guard
                    let funcExpr = argument.expression.as(FunctionCallExprSyntax.self),
                    let type = funcExpr.calledExpression.as(DeclReferenceExprSyntax.self)
                else {
                    throw CustomError.message("The initialContext must be a call to an initialiser.")
                }
                initialContext = funcExpr.description
                initialContextType = type.description
            case "uses", "":
                guard
                    let keyPathExpr = argument.expression.as(KeyPathExprSyntax.self),
                    let first = keyPathExpr.components.first,
                    keyPathExpr.components.count == 1,
                    let component = first.component.as(KeyPathPropertyComponentSyntax.self),
                    component.description.first == "$"
                else {
                    throw CustomError.message("Malformed keypath in `uses` parameter.")
                }
                environment.insert(String(component.description.dropFirst()))
            default:
                continue
            }
        }
        let name = potentialName ?? label.capitalized
        self.init(
            id: -1,
            name: name,
            identifier: label.description,
            context: (initialContext, initialContextType),
            environment: environment
        )
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

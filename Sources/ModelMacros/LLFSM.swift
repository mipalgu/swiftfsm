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
        guard
            let varDecl = memberBlockItem.decl.as(VariableDeclSyntax.self),
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

public struct LLFSM: ExtensionMacro {
    
    /// Expand an attached extension macro to produce the contents that will 
    /// create a set of extensions.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing the attached macro.
    ///   - declaration: The declaration the macro attribute is attached to.
    ///   - type: The type to provide extensions of.
    ///   - protocols: The list of protocols to add conformances to. These will
    ///     always be protocols that `type` does not already state a conformance
    ///     to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: the set of extension declarations introduced by the macro,
    ///   which are always inserted at top-level scope. Each extension must extend
    ///   the `type` parameter.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw CustomError.message("The LLFSM macro can only be attached to a struct.")
        }
        let modifiers = structDecl.modifiers
        var id: Int = 0
        var ids: [String: Int] = [:]
        var labels: [String: String] = [:]
        let states: [StateIdentifier] = try structDecl.memberBlock.members.compactMap {
            guard var state = StateIdentifier(memberBlockItem: $0) else {
                return nil
            }
            guard ids[state.name] == nil else {
                throw CustomError.message("Duplicate state name: \(state.name)")
            }
            guard labels[state.identifier] == nil else {
                throw CustomError.message("Duplicate state identifier: \(state.identifier)")
            }
            let stateID = id
            ids[state.name] = stateID
            id += 1
            state.id = stateID
            labels[state.identifier] = state.name
            return state
        }
        let inheritanceType: TypeSyntax = "LLFSM"
        guard !protocols.contains(inheritanceType) else { return [] }
        let inheritanceClause = InheritanceClauseSyntax(inheritedTypes: [.init(type: inheritanceType)])
        return [
            ExtensionDeclSyntax(
                modifiers: modifiers,
                extendedType: type,
                inheritanceClause: inheritanceClause,
                memberBlock: MemberBlockSyntax(
                    members: []/*MemberBlockItemListSyntax(states.map {
                        MemberBlockItemSyntax(decl: $0.structDecl(modifiers: modifiers))
                    })*/
                )
            )
        ]
    }

}

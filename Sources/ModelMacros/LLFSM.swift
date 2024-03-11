import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
        let states: [StateConstruct] = try structDecl.memberBlock.members.compactMap {
            var state: StateConstruct
            do {
                state = try StateConstruct(memberBlockItem: $0)
            } catch {
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
                    members: MemberBlockItemListSyntax(states.map {
                        MemberBlockItemSyntax(decl: $0.structDecl())
                    })
                )
            )
        ]
    }

}

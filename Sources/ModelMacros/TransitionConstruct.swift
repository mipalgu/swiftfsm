import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct TransitionConstruct {

    var target: String

    var condition: String

    var contextName: String
    
    init(target: String, condition: String = "true", contextName: String = "context") {
        self.target = target
        self.condition = condition
        self.contextName = contextName
    }

    init(codeBlockItem: CodeBlockItemSyntax) throws {
        guard
            let funcExp = codeBlockItem.item.as(FunctionCallExprSyntax.self),
            let declRefExp = funcExp.calledExpression.as(DeclReferenceExprSyntax.self)
        else {
            throw CustomError.message("Transition block must be a function call.")
        }
        guard declRefExp.baseName.description.trimmingCharacters(in: .whitespacesAndNewlines) == "Transition" else {
            throw CustomError.message("Transition block must be a function call to Transition.")
        }
        let arguments = funcExp.arguments
        guard
            let firstArgument = arguments.first,
            firstArgument.label?.description.trimmingCharacters(in: .whitespacesAndNewlines) == "to",
            let targetKeyPath = firstArgument.expression.as(KeyPathExprSyntax.self)
        else {
            throw CustomError.message("Transition block must have a target.")
        }
        guard
            let first = targetKeyPath.components.first,
            targetKeyPath.components.count == 1,
            let component = first.component.as(KeyPathPropertyComponentSyntax.self),
            component.description.first == "$"
        else {
            throw CustomError.message("Malformed keypath in `target` parameter.")
        }
        let target = String(component.description.dropFirst())
        let closure: ClosureExprSyntax
        if let secondArgument = arguments.dropFirst().first(where: {
            $0.label?.description.trimmingCharacters(in: .whitespacesAndNewlines) == "canTransition"
        }) {
            guard let closureExp = secondArgument.expression.as(ClosureExprSyntax.self) else {
                throw CustomError.message("Transition block must have a condition.")
            }
            closure = closureExp
        } else if let trailingClosure = funcExp.trailingClosure {
            closure = trailingClosure
        } else {
            self.init(target: target)
            return
        }
        self.init(
            target: target,
            condition: closure.statements.description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

}

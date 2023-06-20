import FSM

public extension AnyTransition {

    init<Root>(
        to target: KeyPath<Root, StateInformation>,
        canTransition: @Sendable @escaping (Source) -> Bool = { _ in true }
    ) where Target == (Root) -> StateInformation {
        self.init(to: { $0[keyPath: target] }, canTransition: canTransition)
    }

    init<Root>(
        to target: String,
        canTransition: @Sendable @escaping (Source) -> Bool = { _ in true }
    ) where Target == (Root) -> StateInformation {
        let info = StateInformation(name: target)
        self.init(to: { _ in info }, canTransition: canTransition)
    }

}

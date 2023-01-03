public struct AnyTransition<Source, Target: Sendable>: TransitionProtocol {

    private let _canTransition: @Sendable (Source) -> Bool

    public let target: Target

    public init<Base: TransitionProtocol>(_ base: Base) where Base.Source == Source, Base.Target == Target {
        self.target = base.target
        self._canTransition = { base.canTransition(from: $0) }
    }

    public init(to target: Target, canTransition: @Sendable @escaping (Source) -> Bool = { _ in true }) {
        self._canTransition = canTransition
        self.target = target
    }

    public init<Root>(
        to target: KeyPath<Root, StateInformation>,
        canTransition: @Sendable @escaping (Source) -> Bool = { _ in true }
    ) where Target == (Root) -> StateInformation {
        self._canTransition = canTransition
        self.target = { $0[keyPath: target] }
    }

    public init<Root>(
        to target: String,
        canTransition: @Sendable @escaping (Source) -> Bool = { _ in true }
    ) where Target == (Root) -> StateInformation {
        let info = StateInformation(name: target)
        self._canTransition = canTransition
        self.target = { _ in info }
    }

    public func canTransition(from source: Source) -> Bool {
        self._canTransition(source)
    }

}

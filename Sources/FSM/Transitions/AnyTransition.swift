public struct AnyTransition<Source, Target: Sendable>: TransitionProtocol {

    let _canTransition: @Sendable (Source) -> Bool

    public let target: Target

    public init<Base: TransitionProtocol>(_ base: Base) where Base.Source == Source, Base.Target == Target {
        self.target = base.target
        self._canTransition = { base.canTransition(from: $0) }
    }

    public init(to target: Target, canTransition: @Sendable @escaping (Source) -> Bool = { _ in true }) {
        self._canTransition = canTransition
        self.target = target
    }

    public func canTransition(from source: Source) -> Bool {
        self._canTransition(source)
    }

    public func map<NewTarget: Sendable>(
        _ transform: (Target) -> NewTarget
    ) -> AnyTransition<Source, NewTarget> {
        AnyTransition<Source, NewTarget>(to: transform(target), canTransition: _canTransition)
    }

}

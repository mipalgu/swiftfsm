public struct AnyTransition<Source: ContextUser, Target>: TransitionProtocol {

    private let _canTransition: (Source) -> Bool
    private let _target: () -> Target

    public var base: Any

    public var target: Target {
        self._target()
    }

    public init<Base: TransitionProtocol>(_ base: Base) where Base.Source == Source, Base.Target == Target {
        self.base = base
        self._canTransition = { base.canTransition(from: $0) }
        self._target = { base.target }
    }

    public func canTransition(from source: Source) -> Bool {
        self._canTransition(source)
    }

}

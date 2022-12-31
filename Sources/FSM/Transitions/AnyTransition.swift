public struct AnyTransition<Source, Target>: TransitionProtocol {

    private let _canTransition: (Source) -> Bool

    public let target: Target

    public init<Base: TransitionProtocol>(_ base: Base) where Base.Source == Source, Base.Target == Target {
        self.init(to: base.target) { base.canTransition(from: $0) }
    }

    public init(to target: Target, canTransition: @escaping (Source) -> Bool = { _ in true }) {
        self._canTransition = canTransition
        self.target = target
    }

    public init<Root>(
        to target: KeyPath<Root, StateInformation>,
        canTransition: @escaping (Source) -> Bool = { _ in true }
    ) where Target == (Root) -> StateInformation {
        self._canTransition = canTransition
        self.target = { $0[keyPath: target] }
    }

    public init<Root>(
        to target: String,
        canTransition: @escaping (Source) -> Bool = { _ in true }
    ) where Target == (Root) -> StateInformation {
        let info = StateInformation(name: target)
        self._canTransition = canTransition
        self.target = { _ in info }
    }

    public func canTransition(from source: Source) -> Bool {
        self._canTransition(source)
    }

}

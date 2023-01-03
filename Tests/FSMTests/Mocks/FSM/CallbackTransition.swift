import FSM

struct CallbackTransition<Source, Target: Sendable>: TransitionProtocol {

    private let _canTransition: @Sendable (Source) -> Bool

    let target: Target

    init(target: Target, canTransition: @Sendable @escaping (Source) -> Bool) {
        self._canTransition = canTransition
        self.target = target
    }

    func canTransition(from source: Source) -> Bool {
        _canTransition(source)
    }

}

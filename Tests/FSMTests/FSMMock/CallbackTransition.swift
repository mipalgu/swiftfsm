import FSM

struct CallbackTransition<Source, Target>: TransitionProtocol {

    private let _canTransition: (Source) -> Bool

    let target: Target

    init(target: Target, canTransition: @escaping (Source) -> Bool) {
        self._canTransition = canTransition
        self.target = target
    }

    func canTransition(from source: Source) -> Bool {
        _canTransition(source)
    }

}

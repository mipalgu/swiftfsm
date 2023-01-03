public struct FiniteStateMachine<Context: ContextProtocol, Environment: EnvironmentSnapshot> {

    public struct Data: Sendable {

        public private(set) var stateContexts: [Int: Sendable]

        fileprivate private(set) var fsmContext: FSMContext<Context, Environment>

        fileprivate init<Model: FSMModel>(
            model: Model
        ) where Model.Context == Context, Model.Environment == Environment {
            self.stateContexts = model.stateContexts
            self.fsmContext = model.initialContext
        }

    }

    public private(set) var data: Data

    public init<Model: FSMModel>(
        model: Model
    ) where Model.Context == Context, Model.Environment == Environment {
        self.data = Data(model: model)
    }

}

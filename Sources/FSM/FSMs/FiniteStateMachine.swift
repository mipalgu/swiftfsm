public struct FiniteStateMachine {

    public struct Data: DataStructure {

        // private var stateContexts: [Int: Sendable]

        fileprivate init<Model: FSMModel>(model: Model) {
            // self.stateContexts = model.stateContexts
        }

    }

    public private(set) var data: Data

    public init<Model: FSMModel>(model: Model) {
        self.data = Data(model: model)
    }

}

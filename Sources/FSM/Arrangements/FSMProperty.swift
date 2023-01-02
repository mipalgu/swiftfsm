@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementModel, FSM: FSMModel> {

    public let dependencies: [FSMDependency]

    public let projectedValue: FSMInformation

    public let wrappedValue: FSM

    public init(wrappedValue: FSM, dependencies: [FSMDependency]) {
        self.dependencies = dependencies
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

}

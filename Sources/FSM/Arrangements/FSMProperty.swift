@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementModel> {

    public let dependencies: [FSMDependency]

    public let projectedValue: FSMInformation

    public let wrappedValue: any FSMModel

    public init<FSM: FSMModel>(wrappedValue: FSM, dependencies: [FSMDependency]) {
        self.dependencies = dependencies
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

}

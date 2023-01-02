@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementModel> {

    public let projectedValue: FSMInformation

    public let wrappedValue: any FSMModel

    public init<FSM: FSMModel>(wrappedValue: FSM) {
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

}

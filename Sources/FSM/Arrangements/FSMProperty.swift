@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementProtocol> {

    public let projectedValue: FSMInformation

    public let wrappedValue: any FSMModel

    public init<FSM: FSMModel>(wrappedValue: FSM) {
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

}

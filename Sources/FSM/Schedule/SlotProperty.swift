@propertyWrapper
public struct SlotProperty<Arrangement: ArrangementModel> {

    public var projectedValue: Self {
        self
    }

    public var wrappedValue: (Arrangement) -> SlotInformation

    public init(fsm: KeyPath<Arrangement, FSMInformation>, timing: (startTime: UInt, duration: UInt)? = nil) {
        self.wrappedValue = { arrangement in
            SlotInformation(fsm: arrangement[keyPath: fsm], timing: timing)
        }
    }

}

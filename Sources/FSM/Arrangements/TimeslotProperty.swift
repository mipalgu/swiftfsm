public struct TimeslotProperty<Arrangement: ArrangementModel> {

    public let fsm: KeyPath<Arrangement, FSMInformation>

    public let startTime: UInt

    public let duration: UInt

    public var endTime: UInt {
        startTime + duration
    }

    public init(fsm: KeyPath<Arrangement, FSMInformation>, startTime: UInt, duration: UInt) {
        self.fsm = fsm
        self.startTime = startTime
        self.duration = duration
    }

}

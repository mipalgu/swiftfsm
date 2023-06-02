import FSM

public struct SlotInformation: DataStructure {

    public let fsm: FSMInformation

    public let startTime: UInt?

    public let duration: UInt?

    public var endTime: UInt? {
        guard let startTime = startTime, let duration = duration else {
            return nil
        }
        return startTime + duration
    }

    public init(fsm: FSMInformation, timing: (startTime: UInt, duration: UInt)?) {
        self.fsm = fsm
        self.startTime = timing?.startTime
        self.duration = timing?.duration
    }

}

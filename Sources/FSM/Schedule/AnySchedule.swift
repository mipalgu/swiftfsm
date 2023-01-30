public struct AnySchedule<Arrangement: ArrangementProtocol>: ScheduleProtocol {

    public var arrangement: Arrangement

    public var groups: [GroupInformation]

    public init(arrangement: Arrangement, slots: [SlotInformation]) {
        self.init(arrangement: arrangement, groups: [GroupInformation(slots: slots)])
    }

    public init(arrangement: Arrangement, groups: [GroupInformation]) {
        self.arrangement = arrangement
        self.groups = groups
    }

}

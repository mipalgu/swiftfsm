public struct AnySchedule<Arrangement: ArrangementModel>: ScheduleProtocol {

    public var groups: [GroupInformation]

    public init(arrangement: Arrangement.Type, slots: [SlotInformation]) {
        self.init(arrangement: arrangement, groups: [GroupInformation(slots: slots)])
    }

    public init(arrangement _: Arrangement.Type, groups: [GroupInformation]) {
        self.groups = groups
    }

}

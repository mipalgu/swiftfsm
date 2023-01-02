public struct GroupInformation<Arrangement: ArrangementModel> {

    public let timeslots: [TimeslotProperty<Arrangement>]

    public let duration: UInt

    public init(timeslots: [TimeslotProperty<Arrangement>]) {
        self.timeslots = timeslots
        self.duration = timeslots.lazy.map(\.endTime).max() ?? 0
    }

}

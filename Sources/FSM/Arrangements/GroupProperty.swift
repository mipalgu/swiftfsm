public struct GroupProperty<Arrangement: ArrangementModel> {

    public let timeslots: [TimeslotProperty<Arrangement>]

    public init(timeslots: [TimeslotProperty<Arrangement>]) {
        self.timeslots = timeslots
    }

}

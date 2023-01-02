public protocol ArrangementModel {

    var groups: [Group] { get }

}

public extension ArrangementModel {

    typealias FSM<Model: FSMModel> = FSMProperty<Self, Model>

    typealias Group = GroupProperty<Self>

    typealias Timeslot = TimeslotProperty<Self>

}

public protocol ArrangementModel {

    var fsms: [FSM] { get }

    var groups: [GroupInformation<Self>] { get }

}

public extension ArrangementModel {

    typealias FSM = FSMProperty<Self>

    typealias Group = GroupProperty<Self>

    typealias Timeslot = TimeslotProperty<Self>

    var fsms: [FSM] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? FSM
        }
    }

    var groups: [GroupInformation<Self>] {
        let mirror = Mirror(reflecting: self)
        var fsms: [FSM] = []
        var timeslots: [Timeslot] = []
        var groups: [Group] = []
        for child in mirror.children {
            if let fsm = child.value as? FSM {
                fsms.append(fsm)
            } else if let timeslot = child.value as? Timeslot {
                timeslots.append(timeslot)
            } else if let group = child.value as? Group {
                groups.append(group)
            }
        }
        if fsms.isEmpty {
            return []
        }
        guard timeslots.isEmpty || groups.isEmpty else {
            fatalError("Invalid Arrangement: You can only define timeslots in an arrangement if there are no groups.")
        }
        if groups.isEmpty {
            return [GroupInformation(timeslots: timeslots)]
        }
        return groups.map(\.wrappedValue)
    }

}

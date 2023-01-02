public protocol ArrangementModel {

    var fsms: [Machine] { get }

    var groups: [GroupInformation<Self>] { get }

}

public extension ArrangementModel {

    typealias Machine = FSMProperty<Self>

    typealias Group = GroupProperty<Self>

    typealias Timeslot = TimeslotProperty<Self>

    var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

    var groups: [GroupInformation<Self>] {
        let mirror = Mirror(reflecting: self)
        var fsms: [Machine] = []
        var timeslots: [Timeslot] = []
        var groups: [Group] = []
        for child in mirror.children {
            if let fsm = child.value as? Machine {
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

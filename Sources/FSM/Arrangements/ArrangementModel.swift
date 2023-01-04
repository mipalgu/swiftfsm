public protocol ArrangementModel {

    var fsms: [Machine] { get }

    var groups: [GroupInformation] { get }

}

public extension ArrangementModel {

    typealias Machine = FSMProperty<Self>

    typealias Group = GroupProperty<Self>

    typealias Slot = SlotProperty<Self>

    var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

    var groups: [GroupInformation] {
        let mirror = Mirror(reflecting: self)
        var fsms: [Machine] = []
        var slots: [Slot] = []
        var groups: [Group] = []
        for child in mirror.children {
            if let fsm = child.value as? Machine {
                fsms.append(fsm)
            } else if let slot = child.value as? Slot {
                slots.append(slot)
            } else if let group = child.value as? Group {
                groups.append(group)
            }
        }
        if fsms.isEmpty {
            return []
        }
        if groups.isEmpty {
            return [GroupInformation(slots: slots.map { $0.wrappedValue(self) })]
        }
        return groups.map { $0.wrappedValue(self) }
    }

}

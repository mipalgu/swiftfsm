public protocol ScheduleModel: ScheduleProtocol, EmptyInitialisable {}

public extension ScheduleModel {

    typealias Group = GroupProperty<Self>

    typealias Slot = SlotProperty<Arrangement>

    var groups: [GroupInformation] {
        let mirror = Mirror(reflecting: self)
        var slots: [Slot] = []
        var groups: [Group] = []
        for child in mirror.children {
            if let slot = child.value as? Slot {
                slots.append(slot)
            } else if let group = child.value as? Group {
                groups.append(group)
            }
        }
        if groups.isEmpty {
            return [GroupInformation(slots: slots.map { $0.wrappedValue(arrangement) })]
        }
        return groups.map { $0.wrappedValue(self) }
    }

}

public extension ScheduleModel {

    static func main() throws {
        try Self().main()
    }

}

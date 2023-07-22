import FSM

public protocol Schedule: ScheduleProtocol {}

extension Schedule {

    public typealias Group = GroupProperty<Self>

    public typealias Slot = SlotProperty<Arrangement>

    public var groups: [GroupInformation] {
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

extension Schedule where Self: EmptyInitialisable {

    public static func main() throws {
        try Self().main()
    }

}

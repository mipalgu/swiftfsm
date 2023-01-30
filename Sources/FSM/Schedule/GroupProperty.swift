@propertyWrapper
public struct GroupProperty<Schedule: ScheduleModel> {

    public let wrappedValue: (Schedule) -> GroupInformation

    public init(slots keyPaths: KeyPath<Schedule, SlotProperty<Schedule.Arrangement>> ...) {
        self.init(slots: keyPaths)
    }

    public init(slots keyPaths: [KeyPath<Schedule, SlotProperty<Schedule.Arrangement>>]) {
        self.wrappedValue = { schedule in
            GroupInformation(slots: keyPaths.map { schedule[keyPath: $0].wrappedValue(Schedule.Arrangement()) })
        }
    }

}

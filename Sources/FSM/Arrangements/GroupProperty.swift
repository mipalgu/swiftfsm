@propertyWrapper
public struct GroupProperty<Arrangement: ArrangementModel> {

    public let wrappedValue: (Arrangement) -> GroupInformation

    public init(slots keyPaths: KeyPath<Arrangement, SlotProperty<Arrangement>> ...) {
        self.init(slots: keyPaths)
    }

    public init(slots keyPaths: [KeyPath<Arrangement, SlotProperty<Arrangement>>]) {
        self.wrappedValue = { arrangement in
            GroupInformation(slots: keyPaths.map { arrangement[keyPath: $0].wrappedValue(arrangement) })
        }
    }

}

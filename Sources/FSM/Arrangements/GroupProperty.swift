@propertyWrapper
public struct GroupProperty<Arrangement: ArrangementModel> {

    public let wrappedValue: GroupInformation<Arrangement>

    public init(wrappedValue: GroupInformation<Arrangement>) {
        self.wrappedValue = wrappedValue
    }

}

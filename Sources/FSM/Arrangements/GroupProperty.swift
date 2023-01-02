public struct GroupProperty<Arrangement: ArrangementModel> {

    let wrappedValue: GroupInformation<Arrangement>

    public init(wrappedValue: GroupInformation<Arrangement>) {
        self.wrappedValue = wrappedValue
    }

}

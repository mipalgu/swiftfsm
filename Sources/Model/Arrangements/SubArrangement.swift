import FSM

@propertyWrapper
public final class SubArrangement<
    Parent: ArrangementProtocol,
    Arrangement: ArrangementProtocol
>: AnySubArrangement {

    public var wrappedValue: Arrangement

    public var projectedValue: SubArrangement<Parent, Arrangement> {
        self
    }

    public init(wrappedValue: Arrangement) {
        self.wrappedValue = wrappedValue
    }

    public func fsms(namespace: String) -> [Any] {
        wrappedValue.fsms.map { fsm in
            let id = IDRegistrar.id(of: namespace + fsm.projectedValue.name)
            return FSMProperty<Parent>(
                wrappedValue: fsm.wrappedValue,
                projectedValue: FSMInformation(
                    id: id,
                    name: fsm.projectedValue.name,
                    dependencies: fsm.projectedValue.dependencies
                ),
                make: { _ in
                    fsm.make(self.wrappedValue)
                }
            )
        }
    }

}

import FSM

@propertyWrapper
public final class ArrangementSubArrangement<
    Parent: ArrangementProtocol,
    Arrangement: ArrangementProtocol
>: AnySubArrangement {

    public var wrappedValue: Arrangement

    public var projectedValue: ArrangementSubArrangement<Parent, Arrangement> {
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
                )
            ) { _ in
                fsm.make(self.wrappedValue)
            }
        }
    }

}

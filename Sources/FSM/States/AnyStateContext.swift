public class AnyStateContext<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: CustomReflectable {

    let fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [:],
            displayStyle: .class,
            ancestorRepresentation: .generated
        )
    }

    init(fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        self.fsmContext = fsmContext
    }

    public func clone(
        fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>
    ) -> AnyStateContext<FSMsContext, Environment, Parameters, Result> {
        AnyStateContext<FSMsContext, Environment, Parameters, Result>(fsmContext: fsmContext)
    }

}

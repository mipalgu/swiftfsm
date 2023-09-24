public class AnyStateContext<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
> {

    let fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>

    init(fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        self.fsmContext = fsmContext
    }

    public func clone(
        fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>
    ) -> AnyStateContext<FSMsContext, Environment, Parameters, Result> {
        AnyStateContext<FSMsContext, Environment, Parameters, Result>(fsmContext: fsmContext)
    }

}

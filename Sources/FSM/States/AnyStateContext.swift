public class AnyStateContext<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
> {

    var fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>

    init(fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        self.fsmContext = fsmContext
    }

}

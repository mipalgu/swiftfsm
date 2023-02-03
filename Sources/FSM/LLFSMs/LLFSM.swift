public protocol LLFSM: FSMModel
where
    StateType == AnyLLFSMState<Context, Environment, Parameters, Result>,
    Ringlet == LLFSMRinglet<Context, Environment, Parameters, Result>
{}

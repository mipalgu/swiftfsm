#if canImport(Model)

import Model

public protocol LLFSM: FSM
where
    StateType == AnyLLFSMState<Context, Environment, Parameters, Result>,
    Ringlet == LLFSMRinglet<Context, Environment, Parameters, Result>
{}

#endif

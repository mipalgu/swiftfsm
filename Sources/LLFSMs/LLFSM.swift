#if canImport(Model)

import Model

public protocol LLFSM: FSM
where
    StateType == AnyLLFSMState<Context, Environment, Parameters, Result>,
    Ringlet == LLFSMRinglet<Context, Environment, Parameters, Result>
{}

@attached(extension, conformances: LLFSM)
public macro LLFSM() = #externalMacro(module: "ModelMacros", type: "LLFSM")

#endif

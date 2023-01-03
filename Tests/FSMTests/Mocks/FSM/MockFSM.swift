import FSM

protocol MockFSM: FSMModel where
    StateType == AnyMockState<Context, Environment, Parameters, Result>,
    Ringlet == MockRinglet<Context, Environment, Parameters, Result> {}

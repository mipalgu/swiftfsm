import FSM

protocol MockFSM: FSMModel where
    StateType == AnyMockState<Context, Environment>,
    Ringlet == MockRinglet<Context, Environment> {}

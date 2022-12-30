import FSM

protocol MockFSM: FSMModel where
    StateType == AnyMockState<Context, Environment.Snapshot>,
    Ringlet == MockRinglet<Context, Environment.Snapshot> {}

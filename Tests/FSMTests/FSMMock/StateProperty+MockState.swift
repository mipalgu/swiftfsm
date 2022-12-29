import FSM

extension StateProperty {

    init<FSMsContext: DataStructure, Environment: DataStructure>(
        name: String,
        @TransitionBuilder transitions2:
            () -> [AnyTransition<EmptyMockState<FSMsContext, Environment>, (Root) -> StateInformation>]
                = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(wrappedValue: EmptyMockState(), name: name, transitions: transitions2)
    }

}

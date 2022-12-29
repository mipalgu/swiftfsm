// import FSM

// extension StateProperty {

//     init<FSMsContext: DataStructure, Environment: DataStructure>(
//         name: String,
//         @TransitionBuilder transitions: () -> [AnyTransition<EmptyMockState, (Root) -> StateInformation>] = { [] }
//     ) where StateType == AnyMockState<FSMsContext, Environment> {
//         self.init(wrappedValue: EmptyMockState(), name: name, transitions: transitions)
//     }

// }

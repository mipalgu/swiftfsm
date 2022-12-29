// import FSM

// extension StateProperty {

//     init<FSMsContext: DataStructure, Environment: DataStructure>(
//         name: String,
//         @TransitionBuilder transitions: () -> [AnyTransition<EmptyMockState, (Root) -> StateInformation>] = { [] }
//     ) where StateType == AnyMockState<FSMsContext, Environment> {
//         let empty = EmptyMockState(name: name)
//         self.init(wrappedValue: empty, name: name, transitions: transitions)
//     }

// }

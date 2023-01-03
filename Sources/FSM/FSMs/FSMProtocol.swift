public protocol FSMProtocol: ContextUser, EnvironmentUser {

    associatedtype Parameters: DataStructure = EmptyDataStructure

    associatedtype Result: DataStructure = EmptyDataStructure

    associatedtype Ringlet: RingletProtocol where
        Ringlet.StateType == StateType,
        Ringlet.TransitionType == AnyTransition<FSMContext<Context, Environment>, StateID>

    associatedtype StateType: TypeErasedState
        where StateType.FSMsContext == Context,
            StateType.Environment == Environment

}

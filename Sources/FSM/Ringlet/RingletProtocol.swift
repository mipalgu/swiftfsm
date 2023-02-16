/// A ringlet defines how a particular finite state machine may be executed.
///
/// A ringlet takes the form of a pure function, that takes the context of a finite state machine, including the state of the finite state machine (the
/// current state for example), as well as all shared variables and state variables. The ringlet is then responsible for executing the finite state machine
/// (typically by executing the current state), evaluating the transitions, and providing the id of the next state to execute.
public protocol RingletProtocol: ContextUser, EmptyInitialisable {

    /// The type of state that this ringlet can execute.
    associatedtype StateType: TypeErasedState

    /// The type of the transitions that are attached to the states that this ringlet evaluates.
    associatedtype TransitionType: TransitionProtocol
    where
        TransitionType.Source == AnyStateContext<
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >,
        TransitionType.Target == StateID

    /// Execute a single ringlet within the finite state machine contained within the given context.
    ///
    /// - Parameter context: The `SchedulerContext` that contains information particular to the finite state machine, including the
    /// state of the finite state machine (current state, values of variables, whether the finite state machine is suspended, etc.), as well as information
    /// regarding dependent finite state machines (such as whether there are results available for a particular call that this finite state machine has
    /// made).
    ///
    /// - Returns: The id of the next state to execute.
    func execute(
        context: SchedulerContext<
            StateType,
            Context,
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >
    ) -> StateID

}

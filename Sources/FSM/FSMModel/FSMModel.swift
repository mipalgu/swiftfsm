/// A convenience protocol that makes the task of defining executable finite
/// state machines easier.
///
/// This protocol is generally used to create models of finite state machines
/// that can be converted into `Executable`s that can be executed by a
/// scheduler. By utilising this protocol, creation of these executable finite
/// state machines becomes less cumbersome as much of the complexity associated
/// with defining fintie state machines is handled through default
/// implementations.
public protocol FSMModel: FSMProtocol, EmptyInitialisable {

    /// A data structure that defines all the dependencies that this finite
    /// state machine has on the environment and other fsms executing within
    /// the system.
    associatedtype Dependencies: DataStructure, EmptyInitialisable = EmptyDataStructure

    /// The name of this finite state machine.
    var name: String { get }

    /// A keypath to the initial state of this finite state machine.
    ///
    /// Generally one uses a `StateProperty` in order to define states. One can
    /// then utilise this property to mark which of those states is the initial
    /// state. For example:
    /// ```swift
    ///     /// An fsm that follows the `LLFSM` semantics.
    ///     struct FSM: LLFSM {
    ///
    ///         /// A state named 'Ping'.
    ///         @State(name: "Ping")
    ///         var ping
    ///
    ///         /// A keypath to the initial state.
    ///         let initialState = \Self.$ping
    ///
    ///     }
    /// ```
    var initialState: KeyPath<Self, StateInformation> { get }

    /// A keypath to the suspend state of this finite state machine.
    ///
    /// Generally one uses a `StateProperty` in order to define states. One can
    /// then utilise this property to mark which of those states is the initial
    /// state. For example:
    /// ```swift
    ///     /// An fsm that follows the `LLFSM` semantics.
    ///     struct FSM: LLFSM {
    ///
    ///         /// A state named 'Ping'.
    ///         @State(name: "Ping")
    ///         var ping
    ///
    ///         /// A state named 'Suspend'.
    ///         @State(name: "suspend")
    ///         var suspend
    ///
    ///         /// A keypath to the initial state.
    ///         let initialState = \Self.$ping
    ///
    ///         /// A keypath to the suspend state.
    ///         let suspendState = \Self.$suspend
    ///
    ///     }
    /// ```
    ///
    /// - Attention: This property is optional as a state will be automatically
    /// created that will serve as the suspend state if this property is nil.
    var suspendState: KeyPath<Self, StateInformation>? { get }

}

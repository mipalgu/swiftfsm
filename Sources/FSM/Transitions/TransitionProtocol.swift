/// A transition models the mechanism that enables an FSM to transition from
/// one state to another.
/// 
/// Since the FSMs modelled within this framework are Logic-Labelled Finite
/// State Machines, this transition is labelled with a boolean condition which
/// evaluate to true when the transition is valid. That is, this protocol
/// models a transition as a function that evaluates whether the current
/// configuration of the system enables this transition to be taken. Transitions
/// must be modelled as pure function that contain no side-effects. Therefore,
/// implementations of this protocol should note that everything in this
/// protocol is defined as a constant. Any data that this transition needs
/// in order to successfully evaluate whether the transition is valid must
/// be read-only. Implementations of this protocol must make care that they
/// do not store references to other types as reference types cannot guarantee
/// purity.
/// 
/// Besides the requirement of purity, this protocol makes no assumptions on
/// the type of states that are transitioning. These are left to particular
/// implementations. Howevever, this protocol makes an assumption that some data
/// needs to be available in order to evaluate whether the transition can be
/// taken. For this, the transition is a ``ContextUser`` associating a
/// particular type of contextwith this transition. The context type represents
/// a data structure containing all associated data needed to evaluate the
/// transition.
public protocol TransitionProtocol: Sendable {

    /// The source of the transition, i.e. the state that the FSM is currently
    /// in.
    associatedtype Source

    /// The type of the target of the transition, i.e. the state that the FSM
    /// will transition to if this transition is valid.
    associatedtype Target

    /// The id of target of the transition, i.e. the id of the state that the
    /// FSM will transition to if this transition is valid.
    var target: Target { get }

    /// Can this transition be taken?
    /// 
    /// - Parameter source: The source of the transition, i.e. the state that
    /// the FSM is currently in.
    /// 
    /// - Parameter context: The data structure containing the data associated
    /// with this transition.
    /// 
    /// - Returns true if this transition can be taken.
    func canTransition(from source: Source) -> Bool

}

/// Provides a means for conforming types to declare a dependency to a
/// finite state machine.
///
/// This is generally utilised by `FSMModel`'s to calculate the dependencies
/// of the finite state machine they are modelling.
public protocol DependencyCalculatable {

    /// Characterises the dependency to a target finite state machine.
    var dependency: FSMDependency { get }

}

/// The protocol that all ActuatorProperty types must conform to.
/// 
/// This protocol is useful when attempting to fetch a typed actuator property
/// from a structure (such as an `FSMModel`).
public protocol AnyActuatorProperty: AnyEnvironmentProperty {

    /// A type-erased version of the initial value of the actuator.
    var erasedInitialValue: Sendable { get }

}

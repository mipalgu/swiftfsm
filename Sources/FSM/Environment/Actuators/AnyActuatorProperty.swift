public protocol AnyActuatorProperty: AnyEnvironmentProperty {

    var erasedInitialValue: Sendable { get }

}

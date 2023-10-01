import FSM
import Model

public func erase<Handler: ActuatorHandler, Environment: EnvironmentSnapshot>(
    _ handler: Handler,
    mapsTo keyPath: WritableKeyPath<Environment, EnvironmentProtocolWriteOnlyProperty<Handler.Value>>
) -> (PartialKeyPath<Environment>, AnyActuatorHandler) {
    let valuePath = keyPath.appending(path: \.wrappedValue)
    return (valuePath, AnyActuatorHandler(handler, mapsTo: valuePath))
}

public func erase<Handler: ExternalVariableHandler, Environment: EnvironmentSnapshot>(
    _ handler: Handler,
    mapsTo keyPath: WritableKeyPath<Environment, EnvironmentProtocolReadWriteProperty<Handler.Value>>
) -> (PartialKeyPath<Environment>, AnyExternalVariableHandler) {
    let valuePath = keyPath.appending(path: \.wrappedValue)
    return (valuePath, AnyExternalVariableHandler(handler, mapsTo: valuePath))
}

public func erase<Handler: GlobalVariableHandler, Environment: EnvironmentSnapshot>(
    _ handler: Handler,
    mapsTo keyPath: WritableKeyPath<Environment, EnvironmentProtocolReadWriteProperty<Handler.Value>>
) -> (PartialKeyPath<Environment>, AnyGlobalVariableHandler) {
    let valuePath = keyPath.appending(path: \.wrappedValue)
    return (valuePath, AnyGlobalVariableHandler(handler, mapsTo: valuePath))
}

public func erase<Handler: SensorHandler, Environment: EnvironmentSnapshot>(
    _ handler: Handler,
    mapsTo keyPath: WritableKeyPath<Environment, EnvironmentProtocolReadOnlyProperty<Handler.Value>>
) -> (PartialKeyPath<Environment>, AnySensorHandler) {
    let valuePath = keyPath.appending(path: \.wrappedValue)
    return (valuePath, AnySensorHandler(handler, mapsTo: valuePath))
}

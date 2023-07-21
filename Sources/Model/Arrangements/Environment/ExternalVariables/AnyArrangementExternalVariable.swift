import FSM

public protocol AnyArrangementExternalVariable {

    func anyExternalVariable<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> (PartialKeyPath<Environment>, AnyExternalVariableHandler<Environment>)

}

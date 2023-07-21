import FSM

public protocol AnyArrangementGlobalVariable {

    func anyGlobalVariable<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> (PartialKeyPath<Environment>, AnyGlobalVariableHandler<Environment>)

}

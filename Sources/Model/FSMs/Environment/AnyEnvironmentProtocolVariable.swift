public protocol AnyEnvironmentProtocolVariable {

    func valuePath<Environment: EnvironmentProtocol>(
        _ keyPath: PartialKeyPath<Environment>
    ) -> PartialKeyPath<Environment>

}

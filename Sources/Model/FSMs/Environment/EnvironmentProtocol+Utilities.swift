import FSM

extension EnvironmentProtocol {

    public typealias ReadOnly<Value: DataStructure> = EnvironmentProtocolReadOnlyProperty<Value>

    public typealias ReadWrite<Value: DataStructure> = EnvironmentProtocolReadWriteProperty<Value>

    public typealias WriteOnly<Value: DataStructure> = EnvironmentProtocolWriteOnlyProperty<Value>

}

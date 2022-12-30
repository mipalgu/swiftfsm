public protocol GlobalVariableHandler: EnvironmentHandler, DataStructure where Value: GlobalVariableValue {

    var value: Value { get set }

}

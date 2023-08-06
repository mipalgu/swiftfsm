public protocol GlobalVariableHandler: EnvironmentHandler where Value: GlobalVariableValue {

    var value: Value { get set }

}

public protocol GlobalVariableHandler: EnvironmentHandler, CombinationsConvertible
    where Value: GlobalVariableValue {

    var value: Value { get set }

}

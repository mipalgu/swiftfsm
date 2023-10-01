public protocol GlobalVariableHandler: SensorHandler, CombinationsConvertible
    where Value: GlobalVariableValue {

    var value: Value { get set }

}

extension GlobalVariableHandler {

    public func takeSnapshot() -> Value {
        value
    }

}

import InMemoryVariables
import Model

public struct ArrangementMock: Arrangement {

    @Actuator
    public var exitActuator = InMemoryActuator<Bool>(id: "exit", initialValue: false)

    @ExternalVariable
    public var exitExternalVariable = InMemoryExternalVariable<Bool>(id: "exit", initialValue: false)

    @Sensor
    public var exitSensor = InMemorySensor<Bool>(id: "exit", initialValue: false)

    @Machine(
        actuators: (\.$exitActuator, mapsTo: \.$exitActuator),
        externalVariables: (\.$exitExternalVariable, mapsTo: \.$exitExternalVariable),
        sensors: (\.$exitSensor, mapsTo: \.$exitSensor)
    )
    public var pingPong = FSMMock()

    public init() {}

}

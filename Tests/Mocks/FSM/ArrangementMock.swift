import FSM
import InMemoryVariables
import Model

public struct ArrangementMock: Arrangement, EmptyInitialisable {

    @Actuator
    public var exitActuator: InMemoryActuator<Bool>

    @ExternalVariable
    public var exitExternalVariable: InMemoryExternalVariable<Bool>

    @Sensor
    public var exitSensor: InMemorySensor<Bool>

    @Machine(
        actuators: (\.$exitActuator, mapsTo: \.$exitActuator),
        externalVariables: (\.$exitExternalVariable, mapsTo: \.$exitExternalVariable),
        sensors: (\.$exitSensor, mapsTo: \.$exitSensor)
    )
    public var pingPong = FSMMock()

    public init() {
        self.init(name: "exit")
    }

    public init(name: String) {
        self._exitActuator = Actuator(wrappedValue: InMemoryActuator(id: name, initialValue: false))
        self._exitExternalVariable = ExternalVariable(wrappedValue: InMemoryExternalVariable(id: name, initialValue: false))
        self._exitSensor = Sensor(wrappedValue: InMemorySensor(id: name, initialValue: false))
    }

}

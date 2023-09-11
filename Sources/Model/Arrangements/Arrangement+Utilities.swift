import FSM
import InMemoryVariables

extension Arrangement {

    /// A dependency to a write-only environment variable.
    public typealias Actuator<Handler: ActuatorHandler> = ArrangementActuator<Handler>

    /// A dependency to a separate arrangement.
    public typealias SubArrangement<Other: ArrangementProtocol> = ArrangementSubArrangement<Self, Other>

    /// A dependency to an environment variable.
    public typealias ExternalVariable<Handler: ExternalVariableHandler>
        = ArrangementExternalVariable<Handler>

    /// A dependency to a variable shared by all fsms within an `Arrangement`.
    public typealias GlobalVariable<Handler: GlobalVariableHandler>
        = ArrangementGlobalVariable<Handler>

    /// A dependency to a read-only environment variable.
    public typealias Sensor<Handler: SensorHandler> = ArrangementSensor<Handler>

}

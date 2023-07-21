import FSM
import InMemoryVariables

extension Arrangement {

    /// A dependency to a write-only environment variable.
    public typealias Actuator<Handler: ActuatorHandler> = ArrangementEnvironmentVariable<Handler>

    /// A dependency to an environment variable.
    public typealias ExternalVariable<Handler: ExternalVariableHandler>
        = ArrangementEnvironmentVariable<Handler>

    /// A dependency to a variable shared by all fsms within an `Arrangement`.
    public typealias GlobalVariable<Handler: GlobalVariableHandler>
        = ArrangementEnvironmentVariable<Handler>

    /// A dependency to a read-only environment variable.
    public typealias Sensor<Handler: SensorHandler> = ArrangementEnvironmentVariable<Handler>

}

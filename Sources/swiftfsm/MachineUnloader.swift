import FSM

public protocol MachineUnloader {
    func unload(_ fsm: AnyScheduleableFiniteStateMachine)
}

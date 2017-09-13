import FSM

public protocol ScheduleHandler {
    func handleUnloadedMachine(_ fsm: AnyScheduleableFiniteStateMachine) -> Bool
}

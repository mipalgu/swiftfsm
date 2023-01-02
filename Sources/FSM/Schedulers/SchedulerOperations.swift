public protocol SchedulerOperations {

    mutating func call<Result: DataStructure>(
        machine: ParameterisedMachine<Result>,
        with args: KeyValuePairs<String, Sendable>
    ) -> Promise<Result>

    func clock(for fsm: Int) -> any ClockProtocol

    func hasPartialResult(call: Int) -> Bool

    func isFinished(fsm: Int) -> Bool

    func isFulfilled(call: Int) -> Bool

    func isSuspended(fsm: Int) -> Bool

    mutating func partialCall<Result: DataStructure, Partial: DataStructure>(
        machine: ParameterisedMachine<Result>,
        with args: KeyValuePairs<String, Sendable>
    ) -> PartialPromise<Result, Partial>

    func partialResult(of call: Int) -> any DataStructure

    mutating func restart(fsm: Int)

    func result(of call: Int) -> any DataStructure

    mutating func resume(fsm: Int)

    mutating func suspend(fsm: Int)

}

public protocol SchedulerOperations {

    mutating func call<Result: DataStructure>(
        machine: ParameterisedMachine<Result>,
        with args: KeyValuePairs<String, Sendable>
    ) -> Promise<Result>

    func clock(for fsm: Int) -> any ClockProtocol

    func isFulfilled(call: Int) -> Bool

    func result(of call: Int) -> any DataStructure

}

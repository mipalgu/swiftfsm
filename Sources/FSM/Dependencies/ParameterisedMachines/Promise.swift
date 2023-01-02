public struct Promise<Result: DataStructure>: DataStructure, Identifiable {

    public let id: Int

    public var isFulfilled: Bool

    public var result: Result!

    public init(id: Int, isFulfilled: Bool = false, result: Result? = nil) {
        self.id = id
        self.isFulfilled = isFulfilled
        self.result = result
    }

    public mutating func update<Scheduler: SchedulerOperations>(from scheduler: Scheduler) {
        self.isFulfilled = scheduler.isFulfilled(call: id)
        self.result = isFulfilled ? unsafeBitCast(scheduler.result(of: id), to: Result.self) : nil
    }

}

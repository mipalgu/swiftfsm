//public struct PartialPromise<Result: DataStructure, Partial: DataStructure>: DataStructure, AnyPromise {
//
//    let id: Int
//
//    public var hasPartialResult: Bool
//
//    public var isFulfilled: Bool
//
//    public var partialResult: Partial!
//
//    public var result: Result!
//
//    init(
//        id: Int,
//        hasPartialResult: Bool = false,
//        isFulfilled: Bool = false,
//        partialResult: Partial? = nil,
//        result: Result? = nil
//    ) {
//        self.id = id
//        self.hasPartialResult = hasPartialResult
//        self.isFulfilled = isFulfilled
//        self.partialResult = partialResult
//        self.result = result
//    }
//
//    public mutating func update<Scheduler: SchedulerOperations>(from scheduler: Scheduler) {
//        self.hasPartialResult = scheduler.hasPartialResult(call: id)
//        self.isFulfilled = scheduler.isFulfilled(call: id)
//        self.partialResult =
//            hasPartialResult
//            ? unsafeBitCast(scheduler.partialResult(of: id), to: Partial.self)
//            : nil
//        self.result = isFulfilled ? unsafeBitCast(scheduler.result(of: id), to: Result.self) : nil
//    }
//
//}

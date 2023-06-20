//public struct Controller: DataStructure, FiniteStateMachineOperations {
//
//    public let submachine: SubMachine
//
//    public var scheduler: (any SchedulerProtocol)!
//
//    public var isFinished: Bool {
//        scheduler.isFinished(fsm: submachine.id)
//    }
//
//    public var isSuspended: Bool {
//        scheduler.isSuspended(fsm: submachine.id)
//    }
//
//    init(submachine: SubMachine) {
//        self.submachine = submachine
//    }
//
//    public mutating func restart() {
//        scheduler.restart(fsm: submachine.id)
//    }
//
//    public mutating func resume() {
//        scheduler.resume(fsm: submachine.id)
//    }
//
//    public mutating func suspend() {
//        scheduler.suspend(fsm: submachine.id)
//    }
//
//}
//
//extension Controller {
//
//    public static func == (lhs: Controller, rhs: Controller) -> Bool {
//        lhs.submachine == rhs.submachine
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(submachine)
//    }
//
//    public enum CodingKeys: CodingKey {
//
//        case submachine
//
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let submachine = try container.decode(
//            SubMachine.self,
//            forKey: .submachine
//        )
//        self.init(submachine: submachine)
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(submachine, forKey: .submachine)
//    }
//
//}

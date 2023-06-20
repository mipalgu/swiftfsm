//@dynamicCallable
//public struct PartialCaller<Result: DataStructure, Partial: DataStructure>: DataStructure {
//
//    public let parameterisedMachine: ParameterisedMachine<Result>
//
//    public var scheduler: (any SchedulerProtocol)!
//
//    init(parameterisedMachine: ParameterisedMachine<Result>) {
//        self.parameterisedMachine = parameterisedMachine
//    }
//
//    public mutating func dynamicallyCall(
//        withKeywordArguments args: KeyValuePairs<String, Sendable>
//    ) -> PartialPromise<Result, Partial> {
//        scheduler.partialCall(machine: parameterisedMachine, with: args)
//    }
//
//}
//
//extension PartialCaller {
//
//    public static func == (lhs: PartialCaller<Result, Partial>, rhs: PartialCaller<Result, Partial>) -> Bool {
//        lhs.parameterisedMachine == rhs.parameterisedMachine
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(parameterisedMachine)
//    }
//
//    public enum CodingKeys: CodingKey {
//
//        case parameterisedMachine
//
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let parameterisedMachine = try container.decode(
//            ParameterisedMachine<Result>.self,
//            forKey: .parameterisedMachine
//        )
//        self.init(parameterisedMachine: parameterisedMachine)
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(parameterisedMachine, forKey: .parameterisedMachine)
//    }
//
//}

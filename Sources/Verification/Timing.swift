import KripkeStructure

enum Timing: Hashable, Codable, Sendable {

    case beforeOrEqual(Duration)

    case after(Duration)

    var durationValue: Duration {
        switch self {
        case .beforeOrEqual(let duration):
            return duration
        case .after(let duration):
            return duration + Duration.nanoseconds(1)
        }
    }

    var timeValue: UInt {
        durationValue.timeValue
    }

    var condition: Constraint<UInt> {
        switch self {
        case .beforeOrEqual:
            return .lessThanEqual(value: timeValue)
        case .after:
            return .greaterThan(value: timeValue - 1)
        }
    }

}

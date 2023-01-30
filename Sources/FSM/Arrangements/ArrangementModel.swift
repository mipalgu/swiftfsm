public protocol ArrangementModel: ArrangementProtocol, EmptyInitialisable {}

public extension ArrangementModel {

    var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

}

public extension ArrangementModel {

    static func main() throws {
        try defaultSchedule.main()
    }

    static var defaultSchedule: AnySchedule<Self> {
        Self().defaultSchedule
    }

}

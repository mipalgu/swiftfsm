public protocol ArrangementModel: ArrangementProtocol, EmptyInitialisable {}

extension ArrangementModel {

    public var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

}

extension ArrangementModel {

    public static func main() throws {
        try defaultSchedule.main()
    }

    public static var defaultSchedule: AnySchedule<Self> {
        Self().defaultSchedule
    }

}

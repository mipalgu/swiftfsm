import FSM

/// The protocol that all models of arrangements must conform to.
public protocol Arrangement: ArrangementProtocol {}

extension Arrangement {

    /// Automatically compute the fsms that comprise this arrangement.
    public var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

}

extension Arrangement where Self: EmptyInitialisable {

    /// A schedule that executes the finite state machines in this arrangement
    /// in round-robin, in the order in which they are defined.
    public static var defaultSchedule: AnySchedule<Self> {
        Self().defaultSchedule
    }

    /// Execute the default schedule.
    public static func main() throws {
        try defaultSchedule.main()
    }

}

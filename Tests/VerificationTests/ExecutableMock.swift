import Foundation
import FSM

/// A mock of an executable for use with testing.
struct ExecutableMock: Executable, Identifiable, Hashable, Codable {

    /// A unique identifier for each instantiation of this mock.
    var id = UUID()

    var handlers: Handlers {
        Handlers(actuators: [], externalVariables: [], globalVariables: [], sensors: [])
    }

    /// Always returns true.
    func isFinished(context _: AnySchedulerContext) -> Bool {
        true
    }

    /// Always returns true.
    func isSuspended(context _: AnySchedulerContext) -> Bool {
        true
    }

    /// Does nothing.
    func next(context _: AnySchedulerContext) {}

    /// Does nothing.
    func saveSnapshot(context _: AnySchedulerContext) {}

    /// Simply returns the inputs.
    func state(_ id: StateID) -> StateInformation {
        StateInformation(id: id, name: "\(id)")
    }

    /// Does nothing.
    func setup(context _: AnySchedulerContext) {}

    /// Does nothing.
    func takeSnapshot(context _: AnySchedulerContext) {}

    /// Does nothing.
    func tearDown(context _: AnySchedulerContext) {}

}

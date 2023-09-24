import Foundation
import FSM

/// A mock of an executable for use with testing.
struct ExecutableMock: Executable, Identifiable, Hashable, Codable {

    /// A unique identifier for each instantiation of this mock.
    var id = UUID()

    /// Always returns true.
    func isFinished(context _: UnsafePointer<SchedulerContextProtocol>) -> Bool {
        true
    }

    /// Always returns true.
    func isSuspended(context _: UnsafePointer<SchedulerContextProtocol>) -> Bool {
        true
    }

    /// Does nothing.
    func next(context _: UnsafeMutablePointer<SchedulerContextProtocol>) {}

    /// Does nothing.
    func saveSnapshot(context _: UnsafeMutablePointer<SchedulerContextProtocol>) {}

    /// Does nothing.
    func takeSnapshot(context _: UnsafeMutablePointer<SchedulerContextProtocol>) {}

}

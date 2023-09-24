import FSM

public protocol ScheduleProtocol {

    associatedtype Arrangement: ArrangementProtocol

    var arrangement: Arrangement { get }

    var groups: [GroupInformation] { get }

}

extension ScheduleProtocol {

    public func main() throws {
        var contexts: [SchedulerContextProtocol] = []
        let fsms = arrangement.fsms
        contexts.reserveCapacity(fsms.count)
        var data: [ErasedFiniteStateMachineData] = []
        data.reserveCapacity(fsms.count)
        defer {
            for (index, fsm) in fsms.enumerated() {
                fsm.wrappedValue.deallocateData(data[index])
            }
        }
        contexts.withContiguousMutableStorageIfAvailable { contextPtr in
            data.withContiguousMutableStorageIfAvailable { dataPtr in
                var scheduler = RoundRobinScheduler(
                    schedule: self,
                    parameters: [:],
                    contexts: contextPtr.baseAddress!,
                    data: dataPtr.baseAddress!
                )
                while !scheduler.shouldTerminate {
                    scheduler.cycle()
                }
            }
        }
    }

}

extension ScheduleProtocol where Self.Arrangement: EmptyInitialisable {

    public var arrangement: Arrangement { Arrangement() }

}

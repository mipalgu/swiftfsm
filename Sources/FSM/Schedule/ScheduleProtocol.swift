public protocol ScheduleProtocol {

    associatedtype Arrangement: ArrangementModel

    var groups: [GroupInformation] { get }

}

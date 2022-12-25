public protocol Parameterisable: Finishable {

    associatedtype Parameters: Hashable, Codable, Sendable

    associatedtype Result: Hashable, Codable, Sendable

    var result: Result? { get }

}

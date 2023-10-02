public protocol CombinationsConvertible {

    associatedtype Value: Codable, Sendable

    var nonNilValue: Value { get }

}

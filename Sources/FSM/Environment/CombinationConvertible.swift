public protocol CombinationsConvertible {

    associatedtype Value: Codable

    var nonNilValue: Value { get }

}

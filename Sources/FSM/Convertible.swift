public protocol Convertible {

    associatedtype Source

    mutating func convert(from source: Source)

    func update(source: inout Source)

}

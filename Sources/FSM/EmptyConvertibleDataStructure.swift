public struct EmptyConvertibleDataStructure<Source>: DataStructure, Convertible {

    public init() {}

    public mutating func convert(from _: Source) {}

    public func update(source _: inout Source) {}

}

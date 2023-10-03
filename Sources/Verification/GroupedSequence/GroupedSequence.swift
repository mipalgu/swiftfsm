public struct GroupedSequence<Base: Sequence>: Sequence, LazySequenceProtocol {

    public let base: Base
    public let shouldGroup: (Base.Iterator.Element, Base.Iterator.Element) -> Bool

    public init(
        _ base: Base,
        _ shouldGroup: @escaping (Base.Iterator.Element, Base.Iterator.Element) -> Bool
    ) {
        self.base = base
        self.shouldGroup = shouldGroup
    }

    public func makeIterator() -> GroupedSequenceIterator<Base.Iterator> {
        GroupedSequenceIterator(self.base.makeIterator(), self.shouldGroup)
    }

}

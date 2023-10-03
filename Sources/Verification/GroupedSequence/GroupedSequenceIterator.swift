public struct GroupedSequenceIterator<Base: IteratorProtocol>: IteratorProtocol {

    fileprivate var base: Base
    fileprivate let shouldGroup: (Base.Element, Base.Element) -> Bool

    fileprivate var lastElement: Base.Element?

    public init(_ base: Base, _ shouldGroup: @escaping (Base.Element, Base.Element) -> Bool) {
        self.base = base
        self.shouldGroup = shouldGroup
    }

    public mutating func next() -> [Base.Element]? {
        var arr: [Base.Element] = []
        if let last = self.lastElement {
            arr = [last]
        }
        while let element = self.base.next() {
            guard
                let last = self.lastElement,
                false == shouldGroup(last, element)
            else {
                self.lastElement = element
                arr.append(element)
                continue
            }
            self.lastElement = element
            return arr
        }
        self.lastElement = nil
        return arr.isEmpty ? nil : arr
    }

}

protocol SortedOperations: RandomAccessCollection {

    func anyIndex(of: Element) -> Index?

    func count(of: Element) -> Int

    func count(leftOf: Element) -> Int

    func count(rightOf: Element) -> Int

    func count(leftOfAndIncluding: Element) -> Int

    func count(rightOfAndIncluding: Element) -> Int

    func contains(_ element: Element) -> Bool

    mutating func empty()

    func range(of: Element) -> Range<Index>

    func firstIndex(of: Element) -> Index?

    func lastIndex(of: Element) -> Index?

    /**
     *  Search for an element that is ordered as being the same as `element`.
     *
     *  - Parameter element: The element that has the same ordering as the
     *  elements that we are looking for.
     *
     *  - Returns: A tuple indicating whether an element with the same order as
     *  `element` was found and the index of where that element was found within
     *  the collection. If there was no element found with the same ordering as
     *  `element` then the index returned indicates the position within the
     *  collection where a new element with the same ordering of `element` may
     *  be inserted.
     */
    func search(for element: Element) -> (Bool, Index)

    func find(_: Element) -> Self.SubSequence

    func left(of: Element) -> Self.SubSequence

    func left(ofAndIncluding: Element) -> Self.SubSequence

    func right(of: Element) -> Self.SubSequence

    func right(ofAndIncluding: Element) -> Self.SubSequence

    mutating func insert(_: Element)

    mutating func remove(at: Self.Index) -> Element

    mutating func removeSubrange(_: Range<Self.Index>)

    mutating func removeAny(_: Element)

    mutating func removeFirst(_: Element)

    mutating func removeLast(_: Element)

    mutating func removeAll(_: Element)

}

extension SortedOperations {

    @inline(__always)
    func anyIndex(of element: Element) -> Self.Index? {
        let (found, index) = self.search(for: element)
        return found ? index : nil
    }

    @inline(__always)
    func count(of element: Element) -> Int {
        self.find(element).count
    }

    @inline(__always)
    func count(leftOf element: Element) -> Int {
        self.left(of: element).count
    }

    @inline(__always)
    func count(rightOf element: Element) -> Int {
        self.right(of: element).count
    }

    @inline(__always)
    func count(leftOfAndIncluding element: Element) -> Int {
        self.left(ofAndIncluding: element).count
    }

    @inline(__always)
    func count(rightOfAndIncluding element: Element) -> Int {
        self.right(ofAndIncluding: element).count
    }

    @inline(__always)
    func contains(_ element: Element) -> Bool {
        self.anyIndex(of: element) != nil
    }

    @inline(__always)
    func range(of element: Element) -> Range<Self.Index> {
        guard let startIndex = self.firstIndex(of: element), let endIndex = self.lastIndex(of: element) else {
            return self.endIndex ..< self.endIndex
        }
        return startIndex ..< self.index(after: endIndex)
    }

    @inline(__always)
    func find(_ element: Element) -> Self.SubSequence {
        self[self.range(of: element)]
    }

    @inline(__always)
    func left(of element: Element) -> Self.SubSequence {
        self[self.startIndex ..< (self.firstIndex(of: element) ?? self.startIndex)]
    }

    @inline(__always)
    func left(ofAndIncluding element: Element) -> Self.SubSequence {
        self[self.startIndex ..< (self.lastIndex(of: element).map { self.index(after: $0) } ?? self.startIndex)]
    }

    @inline(__always)
    func right(of element: Element) -> Self.SubSequence {
        self[(self.lastIndex(of: element).map { self.index(after: $0) } ?? self.endIndex) ..< self.endIndex]
    }

    @inline(__always)
    func right(ofAndIncluding element: Element) -> Self.SubSequence {
        self[(self.firstIndex(of: element) ?? self.endIndex) ..< self.endIndex]
    }

    @inline(__always)
    mutating func removeAny(_ element: Element) {
        guard let index = self.anyIndex(of: element) else {
            return
        }
        _ = self.remove(at: index)
    }

    @inline(__always)
    mutating func removeFirst(_ element: Element) {
        guard let index = self.firstIndex(of: element) else {
            return
        }
        _ = self.remove(at: index)
    }

    @inline(__always)
    mutating func removeLast(_ element: Element) {
        guard let index = self.lastIndex(of: element) else {
            return
        }
        _ = self.remove(at: index)
    }

    @inline(__always)
    mutating func removeAll(_ element: Element) {
        self.removeSubrange(self.range(of: element))
    }

}

extension SortedOperations where Self.SubSequence: SortedOperations {

    @inline(__always)
    func firstIndex(of element: Element) -> Self.Index? {
        guard let index = self.anyIndex(of: element) else {
            return nil
        }
        return self[self.startIndex ..< index].firstIndex(of: element) ?? index
    }

    @inline(__always)
    func lastIndex(of element: Element) -> Self.Index? {
        guard let index = self.anyIndex(of: element) else {
            return nil
        }
        return self[self.index(after: index) ..< self.endIndex].lastIndex(of: element) ?? index
    }

}

extension SortedOperations where Self: ComparatorContainer {

    func search(for element: Element) -> (Bool, Self.Index) {
        var lower = 0
        var upper = self.count - 1
        while lower <= upper {
            let offset = (lower + upper) / 2
            let currentIndex = self.index(self.startIndex, offsetBy: offset)
            switch self.comparator.compare(lhs: self[currentIndex], rhs: element) {
            case .orderedSame:
                return (true, currentIndex)
            case .orderedDescending:
                upper = offset - 1
            case .orderedAscending:
                lower = offset + 1
            }
        }
        return (false, self.index(self.startIndex, offsetBy: lower))
    }

}

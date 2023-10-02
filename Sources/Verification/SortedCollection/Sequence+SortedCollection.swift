import Foundation

extension Sequence {

    func sortedCollection(
        _ compare: @escaping (Self.Iterator.Element, Self.Iterator.Element) -> ComparisonResult
    ) -> SortedCollection<Self.Iterator.Element> {
        SortedCollection(unsortedSequence: self, comparator: AnyComparator(compare))
    }

}

extension Sequence where Self.Iterator.Element: Comparable {

    func sortedCollection() -> SortedCollection<Self.Iterator.Element> {
        SortedCollection(unsortedSequence: self)
    }

}

extension Sequence where Self: RandomAccessCollection, Self: MutableCollection {

    @inlinable
    mutating func sort(limit: Int, by compare: (Self.Iterator.Element, Self.Iterator.Element) -> Bool) {
        if self.isEmpty {
            return
        }
        @inline(__always) func partition(start: Self.Index, end: Self.Index) -> Self.Index {
            let pivot = self[end]
            var i = start
            var j = start
            while j < end {
                if compare(self[j], pivot) {
                    self.swapAt(i, j)
                    i = self.index(after: i)
                }
                j = self.index(after: j)
            }
            self.swapAt(i, end)
            return i
        }
        @inline(__always) func compute(start: Self.Index, end: Self.Index, targetIndex: Self.Index) {
            if start >= end {
                return
            }
            let p = partition(start: start, end: end)
            compute(start: start, end: self.index(p, offsetBy: -1), targetIndex: targetIndex)
            if p < self.index(targetIndex, offsetBy: -1) {
                compute(start: self.index(after: p), end: end, targetIndex: targetIndex)
            }
        }
        compute(
            start: self.startIndex,
            end: self.index(self.startIndex, offsetBy: self.count - 1),
            targetIndex: self.index(self.startIndex, offsetBy: limit)
        )
    }

    @inlinable
    func sorted(limit: Int, by compare: (Self.Iterator.Element, Self.Iterator.Element) -> Bool) -> Self {
        var copy = self
        copy.sort(limit: limit, by: compare)
        return copy
    }

}

extension Sequence where Self: RandomAccessCollection, Self: MutableCollection, Self.Iterator.Element: Comparable {

    @inlinable
    mutating func sort(limit: Int) {
        self.sort(limit: limit, by: <)
    }

    @inlinable
    func sorted(limit: Int) -> Self {
        self.sorted(limit: limit, by: <)
    }

}

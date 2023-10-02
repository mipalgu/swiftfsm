import Foundation

struct SortedCollectionSlice<Element>: ComparatorContainer {

    let comparator: AnyComparator<Element>

    fileprivate var data: Array<Element>.SubSequence

    init(data: Array<Element>.SubSequence, comparator: AnyComparator<Element>) {
        self.data = data
        self.comparator = comparator
    }

    mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.data.reserveCapacity(minimumCapacity)
    }

}

extension SortedCollectionSlice: Sequence {

    func makeIterator() -> Array<Element>.SubSequence.Iterator {
        self.data.makeIterator()
    }

}

extension SortedCollectionSlice: RandomAccessCollection {

    var count: Int {
        self.data.count
    }

    var endIndex: Array<Element>.SubSequence.Index {
        self.data.endIndex
    }

    var first: Element? {
        self.data.first
    }

    var indices: Array<Element>.SubSequence.Indices {
        self.data.indices
    }

    var startIndex: Array<Element>.SubSequence.Index {
        self.data.startIndex
    }

    subscript(position: Array<Element>.SubSequence.Index) -> Element {
        self.data[position]
    }

    func index(after i: Array<Element>.SubSequence.Index) -> Array<Element>.SubSequence.Index {
        self.data.index(after: i)
    }

    func index(before i: Array<Element>.SubSequence.Index) -> Array<Element>.SubSequence.Index {
        self.data.index(before: i)
    }

    subscript(bounds: Range<Array<Element>.SubSequence.Index>) -> SortedCollectionSlice<Element> {
        SortedCollectionSlice(data: self.data[bounds], comparator: self.comparator)
    }

}

extension SortedCollectionSlice: SortedOperations {

    mutating func empty() {
        self.data = []
    }

    mutating func insert(_ element: Element) {
        self.data.insert(element, at: self.search(for: element).1)
    }

    mutating func remove(at index: Array<Element>.SubSequence.Index) -> Element {
        self.data.remove(at: index)
    }

    mutating func removeSubrange(_ bounds: Range<Array<Element>.SubSequence.Index>) {
        self.data.removeSubrange(bounds)
    }

}

extension SortedCollectionSlice: Equatable where Element: Equatable {

    static func == (lhs: SortedCollectionSlice<Element>, rhs: SortedCollectionSlice<Element>) -> Bool {
        lhs.data == rhs.data
    }

}

extension SortedCollectionSlice: Hashable where Element: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.data)
    }

}

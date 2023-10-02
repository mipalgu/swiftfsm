import Foundation

/**
 *  A sorted, random-access collection.
 *
 *  A `SortedCollection` is a collections that keeps its elements sorted at all
 *  times. This therefore allows the collection to optimize several searching
 *  operations. Use a `SortedCollection` if you want a collection that allows
 *  duplicate elements but also allows quick lookups.
 *
 *  A `SortedCollection` uses a `Comparator` to order the elements. This removes
 *  the need for elements to be `Comparable`. For example, a `SortedCollection`
 *  allows the storing of tuples which are not able to conform to protocols.
 *
 *  If the elements within the collection are `Comparable`, then the
 *  `SortedCollection` provides ways to initialise the collection without a
 *  `Comparator`. This therefore sorts the underlying elements in ascending
 *  order and removes the burden of providing a `Comparator`.
 */
struct SortedCollection<Element>: ComparatorContainer {

    let comparator: AnyComparator<Element>

    fileprivate var data: [Element]

    /**
     *  Create a new empty `SortedCollection`.
     *
     *  - Parameter comparator: The `Comparator` that will be used to sort the
     *  elements.
     *
     *  - Returns: A new empty `SortedCollection` sorted on `comparator`.
     */
    init(comparator: AnyComparator<Element>) {
        self.init(sortedArray: [], comparator: comparator)
    }

    /**
     *  Create a new empty `SortedCollection`.
     *
     *  - Parameter compare: A function that compares two elements and returns a
     *  `ComparisonResult` which will be used to sort the elements.
     *
     *  - Returns: A new empty `SortedCollection` sorted on `compare`.
     */
    init(compare: @escaping (Element, Element) -> ComparisonResult) {
        self.init(comparator: AnyComparator(compare))
    }

    /**
     *  Create a new `SortedCollection` by copying elements from another
     *  unsorted `Sequence`.
     *
     *  When creating the `SortedCollection`, `unsortedSequence`'s elements will
     *  be copied and sorted using `comparator`.
     *
     *  - Parameter unsortedSequence: An unsorted sequence containing the new
     *  `SortedCollection`'s elements.
     *
     *  - Parameter comparator: The `Comparator` that will be used to sort any
     *  future elements being inserted into the collection as well as the
     *  elements within `unsortedSequence`.
     *
     *  - Returns: A new `SortedCollection` containing the elements of
     *  `unsortedSequence` sorted on `comparator`.
     *
     *  - Complexity: O(n ^ 2)
     */
    init<S: Sequence>(unsortedSequence: S, comparator: AnyComparator<Element>) where S.Element == Element {
        self.init(
            sortedArray: unsortedSequence.sorted {
                switch comparator.compare(lhs: $0, rhs: $1) {
                case .orderedAscending:
                    return true
                default:
                    return false
                }
            },
            comparator: comparator
        )
    }

    /**
     *  Create a new `SortedCollection` by copying elements from another
     *  unsorted `Sequence`.
     *
     *  When creating the `SortedCollection`, `unsortedSequence`'s elements will
     *  be copied and sorted using `compare`.
     *
     *  - Parameter unsortedSequence: An unsorted sequence containing the new
     *  `SortedCollection`'s elements.
     *
     *  - Parameter compare: A function that compares two element and return a
     *  `ComparisonResult` which will be used to sort any future elements being
     *  inserted into the collection as well as the elements within
     *  `unsortedSequence`.
     *
     *  - Returns: A new `SortedCollection` containing the elements of
     *  `unsortedSequence` sorted on `compare`.
     *
     *  - Complexity: O(n ^ 2)
     */
    init<S: Sequence>(
        unsortedSequence: S,
        compare: @escaping (Element, Element) -> ComparisonResult
    ) where S.Element == Element {
        self.init(unsortedSequence: unsortedSequence, comparator: AnyComparator(compare))
    }

    /**
     *  Create a new `SortedCollection` by copying elements from another
     *  sorted `Array`.
     *
     *  - Parameter sortedArray: A sorted `Array` containing the new
     *  `SortedCollection`'s elements.
     *
     *  - Parameter comparator: The `Comparator` that will be used to sort any
     *  future elements being inserted into the collection.
     *
     *  - Returns: A new `SortedCollection` containing the elements of
     *  `sortedArray` in the order in which they are given.
     *
     *  - Complexity: O(n)
     *
     *  - Warning: It is important to ensure that the elements in
     *  `sortedArray` are already sorted and conform to the sorting method
     *  provided by `comparator`. If they are not then the behaviour of the
     *  `SortedCollection` is undefined.
     */
    init(sortedArray: [Element], comparator: AnyComparator<Element>) {
        self.data = sortedArray
        self.comparator = comparator
    }

    /**
     *  Create a new `SortedCollection` by copying elements from another
     *  sorted `Array`.
     *
     *  - Parameter sortedArray: A sorted `Array` containing the new
     *  `SortedCollection`'s elements.
     *
     *  - Parameter compare: A function that compares two elements and returns a
     *  `ComparisonResult` which will be used to sort any future elements being
     *  inserted into the collection.
     *
     *  - Returns: A new `SortedCollection` containing the elements of
     *  `sortedArray` in the order in which they are given.
     *
     *  - Complexity: O(n)
     *
     *  - Warning: It is important to ensure that the elements in
     *  `sortedArray` are already sorted and conform to the sorting method
     *  provided by `compare`. If they are not then the behaviour of the
     *  `SortedCollection` is undefined.
     */
    init(sortedArray: [Element], compare: @escaping (Element, Element) -> ComparisonResult) {
        self.init(sortedArray: sortedArray, comparator: AnyComparator(compare))
    }

    mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.data.reserveCapacity(minimumCapacity)
    }

}

extension SortedCollection where Element: Comparable {

    /**
     *  Create a new `SortedCollection` by copying elements from another
     *  unsorted `Sequence`.
     *
     *  When creating the `SortedCollection`, `unsortedSequence`'s elements will
     *  be copied and sorted in ascending order.
     *
     *  - Parameter unsortedSequence: An unsorted sequence containing the new
     *  `SortedCollection`'s elements.
     *
     *  - Returns: A new `SortedCollection` containing the elements of
     *  `unsortedSequence` sorted in ascending order.
     *
     *  - Complexity: O(n ^ 2)
     */
    init<S: Sequence>(unsortedSequence: S) where S.Element == Element {
        self.init(sortedArray: unsortedSequence.sorted())
    }

    /**
     *  Create a new `SortedCollection` by copying elements from another
     *  sorted `Array`.
     *
     *  - Parameter sortedArray: A sorted `Array` containing the new
     *  `SortedCollection`'s elements in ascending order.
     *
     *  - Returns: A new `SortedCollection` containing the elements of
     *  `sortedArray`.
     *
     *  - Complexity: O(n)
     *
     *  - Warning: It is important to ensure that the elements in
     *  `sortedArray` are already sorted in ascending order. If they are not
     *  then the behaviour of the `SortedCollection` is undefined.
     */
    init(sortedArray: [Element]) {
        self.init(sortedArray: sortedArray) {
            if $0 < $1 {
                return .orderedAscending
            }
            if $0 > $1 {
                return .orderedDescending
            }
            return .orderedSame
        }
    }

    init() {
        self.init(sortedArray: [])
    }

    init(minimumCapacity: Int) {
        self.init()
        self.data.reserveCapacity(minimumCapacity)
    }

}

extension SortedCollection: ExpressibleByArrayLiteral where Element: Comparable {

    typealias ArrayLiteralElement = Element

    init(arrayLiteral elements: Element...) {
        self.init(unsortedSequence: elements)
    }

}

extension SortedCollection: Sequence {

    func makeIterator() -> Array<Element>.Iterator {
        self.data.makeIterator()
    }

}

extension SortedCollection: RandomAccessCollection {

    var count: Int {
        self.data.count
    }

    var endIndex: Array<Element>.Index {
        self.data.endIndex
    }

    var first: Element? {
        self.data.first
    }

    var indices: Array<Element>.Indices {
        self.data.indices
    }

    var startIndex: Array<Element>.Index {
        self.data.startIndex
    }

    subscript(position: Array<Element>.Index) -> Element {
        self.data[position]
    }

    func index(after i: Array<Element>.Index) -> Array<Element>.Index {
        self.data.index(after: i)
    }

    func index(before i: Array<Element>.Index) -> Array<Element>.Index {
        self.data.index(before: i)
    }

    subscript(bounds: Range<Array<Element>.Index>) -> SortedCollectionSlice<Element> {
        SortedCollectionSlice(data: self.data[bounds], comparator: self.comparator)
    }

}

extension SortedCollection: SortedOperations {

    mutating func empty() {
        self.data = []
    }

    mutating func insert(_ element: Element) {
        self.data.insert(element, at: self.search(for: element).1)
    }

    mutating func remove(at index: Array<Element>.Index) -> Element {
        self.data.remove(at: index)
    }

    mutating func removeSubrange(_ bounds: Range<Array<Element>.Index>) {
        self.data.removeSubrange(bounds)
    }

}

extension SortedCollection: Equatable where Element: Equatable {

    static func == (lhs: SortedCollection<Element>, rhs: SortedCollection<Element>) -> Bool {
        lhs.data == rhs.data
    }

}

extension SortedCollection: Hashable where Element: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.data)
    }

}

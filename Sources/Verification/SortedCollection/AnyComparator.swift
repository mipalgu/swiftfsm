import Foundation

struct AnyComparator<Element>: Comparator {

    fileprivate var _compare: (Element, Element) -> ComparisonResult

    init<C: Comparator>(_ base: C) where C.Element == Element {
        self._compare = { base.compare(lhs: $0, rhs: $1) }
    }

    init(_ compare: @escaping (Element, Element) -> ComparisonResult) {
        self._compare = compare
    }

    func compare(lhs: Element, rhs: Element) -> ComparisonResult {
        self._compare(lhs, rhs)
    }

}

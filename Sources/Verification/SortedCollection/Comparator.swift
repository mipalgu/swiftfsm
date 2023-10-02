import Foundation

protocol Comparator {

    associatedtype Element

    func compare(lhs: Element, rhs: Element) -> ComparisonResult

}

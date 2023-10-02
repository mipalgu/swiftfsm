protocol ComparatorContainer {

    associatedtype Element

    var comparator: AnyComparator<Element> { get }

}

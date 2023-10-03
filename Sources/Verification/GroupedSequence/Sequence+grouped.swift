extension Collection {

    /**
     *  Split a sequence int sub-arrays where each sub-array contains elements
     *  that conform to `shouldGroup`.
     *
     *  In this example, `grouped(by:)` is used to group an `Array` of `Int`s:
     *  ````
     *      let numbers = [1, 1, 2, 2, 3, 4, 1, 1, 5]
     *      let grouped = numbers.grouped { $0 == $1 }
     *          // [[1, 1], [2, 2], [3], [4], [1, 1], [5]]
     *  ````
     *
     *  - Parameter shouldGroup: A function that returns true when two
     *    elements should be grouped together into a sub-array.
     */
    public func grouped(
        by shouldGroup: (Self.Iterator.Element, Self.Iterator.Element) throws -> Bool
    ) rethrows -> [[Self.Iterator.Element]] {
        guard let first = self.first(where: { _ in true }) else {
            return []
        }
        var groups: [[Self.Iterator.Element]] = [[first]]
        let _: Self.Iterator.Element = try self.dropFirst().reduce(first) {
            let result = try shouldGroup($0, $1)
            if !result {
                groups.append([$1])
                return $1
            }
            groups[groups.endIndex - 1].append($1)
            return $1
        }
        return groups
    }

}

extension Collection where Self.Iterator.Element: Equatable {

    /**
     *  Split a sequence into sub-arrays where each sub-array contains elements
     *  that are equal.
     *
     *  In this example, `grouped()` is used to group an `Array` of `Int`s:
     *  ````
     *      let numbers = [1, 1, 2, 2, 3, 4, 1, 1, 5]
     *      let grouped = numbers.grouped()
     *          // [[1, 1], [2, 2], [3], [4], [1, 1], [5]]
     *  ````
     */
    public func grouped() -> [[Self.Iterator.Element]] {
        self.grouped(by: ==)
    }

}

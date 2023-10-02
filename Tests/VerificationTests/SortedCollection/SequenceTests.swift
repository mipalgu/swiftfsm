import XCTest

@testable import Verification

final class SequenceTests: XCTestCase {

    private static let bigArr: [Int] = Array(0..<10000).shuffled()

    fileprivate func createArray(count: Int) -> [Int] {
        let ones = Array(repeating: 1, count: count)
        let twos = Array(repeating: 2, count: count)
        let threes = Array(repeating: 3, count: count)
        let fours = Array(repeating: 4, count: count)
        let fives = Array(repeating: 5, count: count)
        let arr = threes + fours + fives + twos + ones
        return arr
    }

    fileprivate func createSortedCollection(count: Int) -> SortedCollection<Int> {
        let ones = Array(repeating: 1, count: count)
        let twos = Array(repeating: 2, count: count)
        let threes = Array(repeating: 3, count: count)
        let fours = Array(repeating: 4, count: count)
        let fives = Array(repeating: 5, count: count)
        return SortedCollection(sortedArray: ones + twos + threes + fours + fives)
    }

    func test_sortedCollectionOrdering() {
        let arr = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let col: SortedCollection<Int> = SortedCollection(unsortedSequence: arr)
        XCTAssertEqual(arr, Array(col))
        guard let result = col.first else {
            XCTFail("arr.first returns nil.")
            return
        }
        XCTAssertEqual(1, result)
    }

    func test_sortedCollectionOrderingDescending() {
        let arr = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let col = SortedCollection<Int>(unsortedSequence: arr) {
            if $0 < $1 {
                return .orderedDescending
            }
            if $0 > $1 {
                return .orderedAscending
            }
            return .orderedSame
        }
        XCTAssertEqual(Array(arr.reversed()), Array(col))
        guard let first = col.first else {
            XCTFail("col.first returns nil")
            return
        }
        XCTAssertEqual(5, first)
    }

    func test_sortedCollectionOrderingDescendingInsertingManually() {
        let arr = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        var col = SortedCollection<Int> {
            if $0 < $1 {
                return .orderedDescending
            }
            if $0 > $1 {
                return .orderedAscending
            }
            return .orderedSame
        }
        XCTAssertTrue(col.isEmpty)
        arr.forEach { col.insert($0) }
        XCTAssertEqual(Array(arr.reversed()), Array(col))
        guard let first = col.first else {
            XCTFail("col.first returns nil")
            return
        }
        XCTAssertEqual(5, first)
    }

    func test_binarySearchReturnsNoElementsWhenNoneAreFound() {
        let arr: SortedCollection<Int> = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let results = arr.find(0)
        XCTAssertEqual([], Array(results))
    }

    func test_binarySearchReturnsElementInTheMiddle() {
        let arr: SortedCollection<Int> = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let results = arr.find(3)
        XCTAssertEqual([3, 3], Array(results))
    }

    func test_binarySearchReturnsSingleElements() {
        let arr: SortedCollection<Int> = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let results2 = arr.find(2)
        XCTAssertEqual([2], Array(results2))
        let results4 = arr.find(4)
        XCTAssertEqual([4], Array(results4))
    }

    func test_binarySearchReturnsAllElementsAtTheFront() {
        let arr: SortedCollection<Int> = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let results = arr.find(1)
        XCTAssertEqual([1, 1, 1, 1], Array(results))
    }

    func test_binarySearchReturnsAllElementsAtTheEnd() {
        let arr: SortedCollection<Int> = [1, 1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 5]
        let results = arr.find(5)
        XCTAssertEqual([5, 5, 5, 5, 5], Array(results))
    }

    func test_binarySearchReturnsTheEntireCollection() {
        let arr: SortedCollection<Int> = [1, 1, 1, 1]
        let results = arr.find(1)
        XCTAssertEqual([1, 1, 1, 1], Array(results))
    }

    func test_binarySearchReturnsEmptyCollection() {
        let arr: SortedCollection<Int> = []
        let results = arr.find(0)
        XCTAssertEqual([], Array(results))
    }

    func test_insertingIntoSortedCollection() {
        var collection: SortedCollection<Int> = []
        XCTAssertEqual([], Array(collection))
        collection.insert(1)
        XCTAssertEqual([1], Array(collection))
        collection.insert(2)
        XCTAssertEqual([1, 2], Array(collection))
        collection.insert(2)
        XCTAssertEqual([1, 2, 2], Array(collection))
        collection.insert(0)
        XCTAssertEqual([0, 1, 2, 2], Array(collection))
        collection.insert(-1)
        XCTAssertEqual([-1, 0, 1, 2, 2], Array(collection))
    }

    func test_performance() {
        let arr = self.createSortedCollection(count: 100000)
        measure {
            _ = arr.find(1)
            _ = arr.find(2)
            _ = arr.find(3)
            _ = arr.find(4)
            _ = arr.find(5)
        }
    }

    func test_filterPerformance() {
        let arr = self.createSortedCollection(count: 100000)
        measure {
            _ = arr.filter { $0 == 1 }
            _ = arr.filter { $0 == 2 }
            _ = arr.filter { $0 == 3 }
            _ = arr.filter { $0 == 4 }
            _ = arr.filter { $0 == 5 }
        }
    }

    func test_performanceMissing() {
        let arr = self.createSortedCollection(count: 1000000)
        measure {
            _ = arr.find(0)
        }
    }

    func test_filterPerformanceMissing() {
        let arr = self.createSortedCollection(count: 1000000)
        measure {
            _ = arr.filter { $0 == 0 }
        }
    }

    func test_partialSort() {
        let limit = 3
        let arr = [5, 4, 3, 2, 1, 10, 12, 123, 10, 11, 12, 13, 14, 15, 16, 17, 18, -5, -1, -7]
        let result = arr.sorted(limit: limit)
        XCTAssertEqual(Array(result[..<limit]), [-7, -5, -1])
    }

    // func test_partialSortPerformance() {
    //     let limit = 3
    //     var arr = Self.bigArr
    //     measure {
    //         arr.sort(limit: limit)
    //         _ = arr[..<limit]
    //     }
    // }

    func test_partialSortUsingSortPerformance() {
        let limit = 3
        var arr = Self.bigArr
        measure {
            arr.sort()
            _ = arr[..<limit]
        }
    }

}

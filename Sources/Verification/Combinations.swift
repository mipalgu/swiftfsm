import FSM
import KripkeStructure

struct Combinations<Element>: Sequence {

    private let iterator: () -> AnyIterator<Element>

    private init(iterator: @escaping () -> AnyIterator<Element>) {
        self.iterator = iterator
    }

    init<S: Sequence>(sensors: S) throws where Element == [Any], S.Element == (any SensorHandler) {
        var snapshotSensors: [String: Combinations<Any>] = [:]
        for sensor in sensors where snapshotSensors[sensor.id] == nil {
            snapshotSensors[sensor.id] = try Combinations<Any>(convertible: sensor)
        }
        let combinations = Combinations<[String: Any]>(flatten: snapshotSensors)
        self.iterator = {
            let iterator = combinations.makeIterator()
            return AnyIterator {
                guard let values = iterator.next() else {
                    return nil
                }
                return sensors.map {
                    // swiftlint:disable:next force_unwrapping
                    values[$0.id]!
                }
            }
        }
    }

    func erased() -> Combinations<Any?> {
        Combinations<Any?> {
            let iterator = self.makeIterator()
            return AnyIterator<Any?> {
                iterator.next() as Any??
            }
        }
    }

    func makeIterator() -> AnyIterator<Element> {
        self.iterator()
    }

}

extension Combinations where Element == Bool {

    init() {
        self.iterator = {
            var value: Bool? = false
            return AnyIterator {
                guard let out = value else {
                    return nil
                }
                value = out ? nil : true
                return out
            }
        }
    }

}

extension Combinations where Element: FixedWidthInteger {

    init() {
        self.iterator = {
            var value: Element? = Element.min
            return AnyIterator {
                guard let out = value else {
                    return nil
                }
                value = out == Element.max ? nil : out.advanced(by: 1)
                return out
            }
        }
    }

}

extension Combinations where Element: FloatingPoint {

    init() {
        self.iterator = {
            var value: Element? = Element.greatestFiniteMagnitude
            return AnyIterator {
                guard let out = value, !out.isInfinite && !out.isNaN else {
                    return nil
                }
                value = out.nextDown
                return out
            }
        }
    }

}

extension Combinations {

    init<C: Collection, T>(flatten combinations: C) where C.Element == Combinations<T>, Element == [T] {
        if combinations.isEmpty {
            self.init {
                var value = true
                return AnyIterator {
                    guard value else {
                        return nil
                    }
                    value = false
                    return []
                }
            }
            return
        }
        let initial: [Combinations<T>] = Array(combinations)
        let initialPos = initial.count - 1
        self.init {
            var iterators = initial.map { $0.makeIterator() }
            var pos = initialPos
            var current: [T] = iterators.map { $0.next()! }
            return AnyIterator {
                if pos < 0 {
                    return nil
                }
                let out = current
                var nextValue: T?
                while pos >= 0 {
                    nextValue = iterators[pos].next()
                    if let value = nextValue {
                        current[pos] = value
                        break
                    }
                    iterators[pos] = initial[pos].makeIterator()
                    current[pos] = iterators[pos].next()!
                    pos -= 1
                }
                if nextValue == nil {
                    return out
                }
                pos = initialPos
                return out
            }
        }
    }

    init<Key: Hashable, Value>(
        flatten combinations: [Key: Combinations<Value>]
    ) where Key: Comparable, Element == [Key: Value] {
        let sorted = combinations.sorted { $0.key < $1.key }
        let keys = sorted.map { $0.key }
        let flattened = Combinations<[Value]>(flatten: sorted.map { $0.value })
        self.init {
            let iterator = flattened.makeIterator()
            return AnyIterator {
                guard let values = iterator.next() else {
                    return nil
                }
                return Dictionary(uniqueKeysWithValues: zip(keys, values))
            }
        }
    }

}

extension Combinations where Element == KripkeStateProperty {

    init(property: KripkeStateProperty) {
        func createFromProperty(_ property: KripkeStateProperty) -> Combinations<KripkeStateProperty> {
            switch property.type {
            case .Bool:
                let combinations = Combinations<Bool>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .Bool, value: $0) }
                    }
                }
            case .Int:
                let combinations = Combinations<Int>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .Int, value: $0) }
                    }
                }
            case .Int8:
                let combinations = Combinations<Int8>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .Int8, value: $0) }
                    }
                }
            case .Int16:
                let combinations = Combinations<Int16>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .Int16, value: $0) }
                    }
                }
            case .Int32:
                let combinations = Combinations<Int32>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .Int32, value: $0) }
                    }
                }
            case .Int64:
                let combinations = Combinations<Int64>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .Int64, value: $0) }
                    }
                }
            case .UInt:
                let combinations = Combinations<UInt>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .UInt, value: $0) }
                    }
                }
            case .UInt8:
                let combinations = Combinations<UInt8>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .UInt8, value: $0) }
                    }
                }
            case .UInt16:
                let combinations = Combinations<UInt16>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .UInt16, value: $0) }
                    }
                }
            case .UInt32:
                let combinations = Combinations<UInt32>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .UInt32, value: $0) }
                    }
                }
            case .UInt64:
                let combinations = Combinations<UInt64>()
                return Combinations<KripkeStateProperty> {
                    let iterator = combinations.makeIterator()
                    return AnyIterator {
                        iterator.next().map { KripkeStateProperty(type: .UInt64, value: $0) }
                    }
                }
            case .Compound(let compoundProperties):
                let combinations = createFromProperties(compoundProperties)
                let flattened = Combinations<[String: KripkeStateProperty]>(flatten: combinations)
                return Combinations<KripkeStateProperty> {
                    let iterator = flattened.makeIterator()
                    return AnyIterator {
                        iterator.next().map {
                            KripkeStateProperty(
                                type: .Compound(KripkeStatePropertyList($0)),
                                value: $0.mapValues(\.value)
                            )
                        }
                    }
                }
            default:
                fatalError("Attempting to create combinations of unsupported type: \(Element.self)")
            }
        }
        func createFromProperties(
            _ plist: KripkeStatePropertyList
        ) -> [String: Combinations<KripkeStateProperty>] {
            plist.properties.mapValues { (value: KripkeStateProperty) -> Combinations<KripkeStateProperty> in
                createFromProperty(value)
            }
        }
        self = createFromProperty(property)
    }

}

extension Combinations where Element: Codable {

    init(for element: Element) throws {
        let encoder = KripkeStatePropertyEncoder()
        let decoder = KripkeStatePropertyDecoder()
        let property = try encoder.encode(element)
        let propertyCombinations = Combinations<KripkeStateProperty>(property: property)
        self.init {
            let iterator = propertyCombinations.makeIterator()
            return AnyIterator {
                iterator.next().map {
                    guard let value = try? decoder.decode(Element.self, from: $0) else {
                        fatalError("Cannot decode property: \($0)")
                    }
                    return value
                }
            }
        }
    }

}

extension Combinations where Element == Any {

    init<Convertible: CombinationsConvertible>(
        convertible: Convertible
    ) throws {
        let combinations = try Combinations<Convertible.Value>(for: convertible.nonNilValue)
        self.init {
            let iterator = combinations.makeIterator()
            return AnyIterator<Any> { iterator.next().map { $0 as Any } }
        }
    }

}

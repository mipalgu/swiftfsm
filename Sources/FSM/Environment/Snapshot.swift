public struct Snapshot<Data: EnvironmentSnapshot> {

    private var data: Data

    private let whitelist: Set<PartialKeyPath<Data>>

    public init(data: Data, whitelist: Set<PartialKeyPath<Data>>) {
        self.data = data
        self.whitelist = whitelist
    }

    public func get<T>(_ keyPath: KeyPath<Data, T>) -> T {
        guard !whitelist.contains(keyPath) else {
            fatalError("Attempting to access restricted member.")
        }
        return data[keyPath: keyPath]
    }

    public mutating func set<T>(_ keyPath: WritableKeyPath<Data, T>, _ newValue: T) {
        guard !whitelist.contains(keyPath) else {
            fatalError("Attempting to access restricted member.")
        }
        data[keyPath: keyPath] = newValue
    }

}

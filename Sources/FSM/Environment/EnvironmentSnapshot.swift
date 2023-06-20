public protocol EnvironmentSnapshot: DataStructure, EmptyInitialisable {

    mutating func update<T>(keyPath: WritableKeyPath<Self, T>, value: T)

}

extension EnvironmentSnapshot {

    public mutating func update<T>(keyPath: WritableKeyPath<Self, T>, value: T) {
        self[keyPath: keyPath] = value
    }

}

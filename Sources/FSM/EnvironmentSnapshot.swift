public protocol EnvironmentSnapshot: DataStructure, EmptyInitialisable {

    mutating func update<T>(keyPath: WritableKeyPath<Self, T>, value: T)

}

public extension EnvironmentSnapshot {

    mutating func update<T>(keyPath: WritableKeyPath<Self, T>, value: T) {
        self[keyPath: keyPath] = value
    }

}

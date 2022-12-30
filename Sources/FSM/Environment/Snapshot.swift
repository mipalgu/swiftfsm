@dynamicMemberLookup
public struct Snapshot<Data: EnvironmentSnapshot> {

    private var data: Data

    private let whitelist: Set<PartialKeyPath<Data>>

    public init(data: Data, whitelist: Set<PartialKeyPath<Data>>) {
        self.data = data
        self.whitelist = whitelist
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Data, T>) -> T {
        guard whitelist.contains(keyPath) else {
            fatalError("Attempting to access restricted member.")
        }
        return data[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Data, T>) -> T {
        get {
            guard whitelist.contains(keyPath) else {
                fatalError("Attempting to access restricted member.")
            }
            return data[keyPath: keyPath]
        }
        set {
            guard whitelist.contains(keyPath) else {
                fatalError("Attempting to access restricted member.")
            }
            data[keyPath: keyPath] = newValue
        }
    }

}

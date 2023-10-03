public enum ExecutableDependency: Hashable, Codable, Sendable {

    case async(id: Int)

    case sync(id: Int)

    case submachine(id: Int)

    public var isAsync: Bool {
        switch self {
        case .async:
            return true
        default:
            return false
        }
    }

    public var isSync: Bool {
        switch self {
        case .sync:
            return true
        default:
            return false
        }
    }

    public var isSubMachine: Bool {
        switch self {
        case .submachine:
            return true
        default:
            return false
        }
    }

    public var id: Int {
        switch self {
        case .sync(let id), .async(let id), .submachine(let id):
            return id
        }
    }

}

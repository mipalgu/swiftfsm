public final class IDRegistrar {

    private static var latestID: Int = 0

    private static var ids: [Int: String] = [:]

    private static var names: [String: Int] = [:]

    private init() {}

    public static func id(of name: String) -> Int {
        if let id = names[name] {
            return id
        }
        let id = latestID
        latestID = latestID &+ 1
        ids[id] = name
        names[name] = id
        return id
    }

    public static func name(of id: Int) -> String? {
        ids[id]
    }

    internal static func removeAll() {
        ids.removeAll()
        names.removeAll()
    }

}

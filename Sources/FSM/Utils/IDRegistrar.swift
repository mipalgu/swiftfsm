public final class IDRegistrar {

    private static var latestID: Int = 0

    private static var ids: [Int: String] = [:]

    private static var names: [String: Int] = [:]

    private init() {}

    public static func id(of state: String) -> Int {
        if let id = names[state] {
            return id
        }
        let id = latestID
        latestID += 1
        ids[id] = state
        names[state] = id
        return id
    }

    public static func name(of state: Int) -> String? {
        ids[state]
    }

}

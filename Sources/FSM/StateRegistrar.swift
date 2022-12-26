final class StateRegistrar {

    private static var latestID: Int = 0

    private static var states: [Int: String] = [:]

    private static var names: [String: Int] = [:]

    private init() {}

    static func id(of state: String) -> Int {
        if let id = names[state] {
            return id
        }
        let id = latestID
        latestID += 1
        states[id] = state
        names[state] = id
        return id
    }

    static func name(of state: Int) -> String? {
        states[state]
    }

}

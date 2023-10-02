import KripkeStructure

struct RingletResult: Hashable {

    var postSnapshot: KripkeStatePropertyList

    var calls: [Call]

    init(ringlet: Ringlet) {
        self.init(postSnapshot: ringlet.postSnapshot, calls: ringlet.calls)
    }

    init(postSnapshot: KripkeStatePropertyList, calls: [Call]) {
        self.postSnapshot = postSnapshot
        self.calls = calls
    }

}

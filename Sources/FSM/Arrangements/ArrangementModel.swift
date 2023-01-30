public protocol ArrangementModel: EmptyInitialisable {

    var fsms: [Machine] { get }

}

public extension ArrangementModel {

    typealias Machine = FSMProperty<Self>

    var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

}

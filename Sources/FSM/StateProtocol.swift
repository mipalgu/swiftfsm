public protocol StateProtocol: ContextUser {

    associatedtype TypeErasedVersion

    init(name: String)

}

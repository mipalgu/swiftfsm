public protocol StateProtocol: ContextUser {

    associatedtype TypeErasedVersion: TypeErasedState

    var erased: TypeErasedVersion { get }

}

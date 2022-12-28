public protocol StateProtocol: ContextUser, EnvironmentUser {

    associatedtype OwnerContext: DataStructure = EmptyDataStructure
    associatedtype OwnerEnvironment: DataStructure = EmptyDataStructure
    associatedtype TypeErasedVersion: TypeErasedState

    var erased: TypeErasedVersion { get }

}

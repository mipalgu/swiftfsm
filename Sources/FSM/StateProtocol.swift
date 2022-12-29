public protocol StateProtocol: ContextUser, EnvironmentUser {

    associatedtype OwnerContext: DataStructure = EmptyDataStructure
    associatedtype TypeErasedVersion: TypeErasedState where
        TypeErasedVersion.FSMsContext == OwnerContext,
        TypeErasedVersion.Environment == Environment

    var erased: TypeErasedVersion { get }

}

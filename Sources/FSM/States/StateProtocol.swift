public protocol StateProtocol: ContextUser, EnvironmentUser {

    associatedtype FSMsContext: DataStructure = EmptyDataStructure
    associatedtype TypeErasedVersion: TypeErasedState where
        TypeErasedVersion.FSMsContext == FSMsContext,
        TypeErasedVersion.Environment == Environment

    var erased: TypeErasedVersion { get }

}

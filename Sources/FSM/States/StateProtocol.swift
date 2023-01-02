public protocol StateProtocol: ContextUser, EnvironmentUser {

    associatedtype FSMsContext: ContextProtocol = EmptyDataStructure
    associatedtype TypeErasedVersion: TypeErasedState where
        TypeErasedVersion.FSMsContext == FSMsContext,
        TypeErasedVersion.Environment == Environment

    var erased: TypeErasedVersion { get }

}

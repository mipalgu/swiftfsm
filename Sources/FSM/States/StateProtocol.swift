public protocol StateProtocol: ContextUser, EnvironmentUser {

    associatedtype FSMsContext: ContextProtocol = EmptyDataStructure
    associatedtype Parameters: DataStructure = EmptyDataStructure
    associatedtype Result: DataStructure = EmptyDataStructure
    associatedtype TypeErasedVersion: TypeErasedState where
        TypeErasedVersion.FSMsContext == FSMsContext,
        TypeErasedVersion.Environment == Environment,
        TypeErasedVersion.Parameters == Parameters,
        TypeErasedVersion.Result == Result

    var erased: TypeErasedVersion { get }

}

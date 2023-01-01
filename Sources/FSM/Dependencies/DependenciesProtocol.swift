public protocol DependenciesProtocol: DataStructure, EmptyInitialisable {}

public extension DependenciesProtocol {

    typealias Async<Result: DataStructure> = ASyncProperty<Result>

    typealias Sync<Result: DataStructure> = SyncProperty<Result>

    typealias SubMachine = SubMachineProperty

}

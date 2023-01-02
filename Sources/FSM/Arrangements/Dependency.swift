public struct Dependency: DataStructure {

    public let fsm: Int

    public let dependency: FSMDependency

    public init(to fsm: Int, satisfying dependency: FSMDependency) {
        self.fsm = fsm
        self.dependency = dependency
    }

}

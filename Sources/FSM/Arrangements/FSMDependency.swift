public enum FSMDependency: DataStructure {

    case async(id: Int)

    case sync(id: Int)

    case partial(id: Int)

    case submachine(id: Int)

}

public extension FSMModel {

    var defaultArrangement: SingleMachineArrangement {
        SingleMachineArrangement(fsm: self)
    }

    func main() throws {
        try defaultArrangement.main()
    }

    static var defaultArrangement: SingleMachineArrangement {
        Self().defaultArrangement
    }

    static func main() throws {
        try Self().main()
    }

}

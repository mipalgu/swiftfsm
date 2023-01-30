public extension FSMModel {

    var defaultArrangement: SingleMachineArrangement<Self> {
        SingleMachineArrangement(machine: self)
    }

    func main() throws {
        try defaultArrangement.main()
    }

    static var defaultArrangement: SingleMachineArrangement<Self> {
        Self().defaultArrangement
    }

    static func main() throws {
        try Self().main()
    }

}

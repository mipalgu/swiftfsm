import FSM

extension FSM {

    public var defaultArrangement: SingleMachineArrangement {
        SingleMachineArrangement(fsm: self)
    }

    public func main() throws {
        try defaultArrangement.main()
    }

}

extension FSM where Self: EmptyInitialisable {

    public static var defaultArrangement: SingleMachineArrangement {
        Self().defaultArrangement
    }

    public static func main() throws {
        try Self().main()
    }

}
struct IsolatedThread {

    var map: VerificationMap

    var pool: ExecutablePool

    // mutating func setParameters(of callee: String, to parameters: [String: Any?]) {
    //     self.pool = pool.cloned
    //     guard let fsm = self.pool.fsm(callee).asParameterisedFiniteStateMachine else {
    //         fatalError("Unable to fetch parameterised fsm \(callee)")
    //     }
    //     guard fsm.parametersFromDictionary(parameters) else {
    //         fatalError("Unable to set parameters of \(callee)")
    //     }
    // }

}

import FSM

public extension AnyExternalVariableHandler {

    init<Base: ExternalVariableHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self.init(base) {
            $0.pointee[keyPath: keyPath] = $1 as! Base.Value
        }
    }

}

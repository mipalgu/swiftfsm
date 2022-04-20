import swiftfsm

public struct SonarStateTransition: TransitionType {
    
    internal let base: Any
    
    public let target: SonarState
    
    public let canTransition: (SonarState) -> Bool
    
    public init<S: SonarState>(_ base: Transition<S, SonarState>) {
        self.base = base
        self.target = base.target
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    internal init(base: Any, target: SonarState, canTransition: @escaping (SonarState) -> Bool) {
        self.base = base
        self.target = target
        self.canTransition = canTransition
    }
    
    public func cast<S: SonarState>(to type: S.Type) -> Transition<S, SonarState> {
        guard let transition = self.base as? Transition<S, SonarState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (SonarState) -> SonarState) -> SonarStateTransition {
        return SonarStateTransition(base: base, target: f(self.target), canTransition: self.canTransition)
    }
    
}
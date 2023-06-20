import FSM
import LLFSMs

public struct NamedLLFSMState: LLFSMState {

    public let name: String

    public init(name: String) {
        self.name = name
    }

}

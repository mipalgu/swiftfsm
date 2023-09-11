import FSM
import InMemoryVariables
import Model

public struct ArrangementOfArrangementMock: Arrangement, EmptyInitialisable {

    @SubArrangement
    public var arrangement1 = ArrangementMock(name: "arrangement1")

    @SubArrangement
    public var arrangement2 = ArrangementMock(name: "arrangement2")

    public init() {}

}

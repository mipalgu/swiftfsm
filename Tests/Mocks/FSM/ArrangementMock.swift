import Model

public struct ArrangementMock: ArrangementModel {

    @Machine
    public var pingPong = FSMMock()

    public init() {}

}

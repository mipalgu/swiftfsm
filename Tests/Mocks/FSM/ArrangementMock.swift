import Model

public struct ArrangementMock: Arrangement {

    @Machine
    public var pingPong = FSMMock()

    public init() {}

}

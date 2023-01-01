public protocol ClockProtocol {

    func after(_ seconds: Int) -> Bool

    func after_ms(_ milliseconds: Int) -> Bool

}

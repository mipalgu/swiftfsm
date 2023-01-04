public struct RoundRobinScheduler {

    public func run<Arrangement: ArrangementModel>(arrangement: Arrangement) {
        let fsms = arrangement.fsms.map(\.wrappedValue)
    }

}

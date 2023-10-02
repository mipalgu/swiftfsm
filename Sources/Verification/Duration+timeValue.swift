extension Duration {

    var timeValue: UInt {
        let attoSecondsAsNanoSeconds = components.attoseconds / 1_000_000_000
        let secondsAsNanoSeconds = components.seconds * 1_000_000_000
        return UInt(attoSecondsAsNanoSeconds + secondsAsNanoSeconds)
    }

}

public struct GroupInformation {

    public let slots: [SlotInformation]

    public let duration: UInt?

    public init(slots: [SlotInformation]) {
        self.slots = slots
        let endSlots = slots.compactMap(\.endTime)
        guard endSlots.count == slots.count else {
            self.duration = nil
            return
        }
        self.duration = endSlots.max()
    }

}

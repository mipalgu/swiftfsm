extension LazySequenceProtocol {

    func grouped(
        by shouldGroup: @escaping (Self.Iterator.Element, Self.Iterator.Element) -> Bool
    ) -> GroupedSequence<Self> {
        GroupedSequence(self, shouldGroup)
    }

}

extension LazySequenceProtocol where Self.Iterator.Element: Equatable {

    func grouped() -> GroupedSequence<Self> {
        GroupedSequence(self, ==)
    }

}

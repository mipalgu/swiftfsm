import FSM
import KripkeStructure

/// A ringlet that is only taken when a condition on the fsm's clock is true.
struct ConditionalRinglet {

    /// The timeslot where the fsm was executing.
    var timeslot: Timeslot

    /// The state of all fsms before this ringlet executed.
    var before: ExecutablePool

    /// The state of all fsms after this ringlet executed.
    var after: ExecutablePool

    /// Did the fsm transition during the ringlet execution?
    var transitioned: Bool

    /// The evaluation of all the variables within the FSM before the
    /// ringlet has executed.
    var preSnapshot: KripkeStatePropertyList

    /// The evaluation of all the variables within the FSM after the ringlet has
    /// finished executing.
    var postSnapshot: KripkeStatePropertyList

    /// A list of calls made to parameterised machines during the execution of
    /// the ringlet.
    var calls: [Call]

    /// The condition on the clock when this ringlet is able to execute.
    var condition: Constraint<UInt>

    init(ringlet: Ringlet, condition: Constraint<UInt>) {
        self.init(
            timeslot: ringlet.timeslot,
            before: ringlet.before,
            after: ringlet.after,
            transitioned: ringlet.transitioned,
            preSnapshot: ringlet.preSnapshot,
            postSnapshot: ringlet.postSnapshot,
            calls: ringlet.calls,
            condition: condition
        )
    }

    /// Create a `ConditionalRinglet`.
    init(
        timeslot: Timeslot,
        before: ExecutablePool,
        after: ExecutablePool,
        transitioned: Bool,
        preSnapshot: KripkeStatePropertyList,
        postSnapshot: KripkeStatePropertyList,
        calls: [Call],
        condition: Constraint<UInt>
    ) {
        self.timeslot = timeslot
        self.before = before
        self.after = after
        self.transitioned = transitioned
        self.preSnapshot = preSnapshot
        self.postSnapshot = postSnapshot
        self.calls = calls
        self.condition = condition
    }

}

extension ConditionalRinglet: Hashable {

    static func == (lhs: ConditionalRinglet, rhs: ConditionalRinglet) -> Bool {
        lhs.transitioned == rhs.transitioned
        && lhs.preSnapshot == rhs.preSnapshot
        && lhs.postSnapshot == rhs.postSnapshot
        && lhs.calls == rhs.calls
        && lhs.condition == rhs.condition
        && lhs.timeslot == rhs.timeslot
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(transitioned)
        hasher.combine(preSnapshot)
        hasher.combine(postSnapshot)
        hasher.combine(calls)
        hasher.combine(condition)
        hasher.combine(timeslot)
    }

}

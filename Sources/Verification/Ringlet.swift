import FSM
import KripkeStructure

/// Represents a single ringlet execution at a specific time for a specific
/// FSM.
///
/// This struct generates a `KripkeStatePropertyList` before and after the
/// ringlet execution. This struct also records and calls that were made to
/// parameterised machines as well as any calls to the fsms clock.
struct Ringlet {

    /// The timeslot where the fsm was executed.
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

    /// A list of clock values which were queried during the execution of the
    /// ringlet.
    var afterCalls: Set<Duration>

    /// Create a `Ringlet`.
    ///
    /// Executes the ringlet of the fsm by calling `next`. Uses introspection
    /// to query the variables to create the `Ringlet` structure.
    ///
    /// - Parameter fsm The fsm being inspected to create this ringlet.
    ///
    /// - Parameter gateway The `ModifiableFSMGateway` responsible for handling
    /// parameterised machine invocations. A delegate is created and used to
    /// detect when the fsm makes any calls to other machines.
    init(pool: ExecutablePool, timeslot: Timeslot) {
        let afterPool = pool.cloned
        let executableID = timeslot.callChain.executable
        let element = afterPool.executables[pool.index(of: executableID)]
        element.executable.setup(context: element.context)
        let preSnapshot = KripkeStatePropertyList(element.context)
        element.executable.tearDown(context: element.context)
        element.context.afterCalls.removeAll(keepingCapacity: true)
        element.executable.next(context: element.context)
        element.executable.setup(context: element.context)
        let postSnapshot = KripkeStatePropertyList(element.context)
        element.executable.tearDown(context: element.context)
        let transitioned = element.context.transitioned
        let calls: [Call] = []
        self.init(
            timeslot: timeslot,
            before: pool,
            after: afterPool,
            transitioned: transitioned,
            preSnapshot: preSnapshot,
            postSnapshot: postSnapshot,
            calls: calls,
            afterCalls: Set(element.context.afterCalls)
        )
    }

    /// Create a `Ringlet`.
    init(
        timeslot: Timeslot,
        before: ExecutablePool,
        after: ExecutablePool,
        transitioned: Bool,
        preSnapshot: KripkeStatePropertyList,
        postSnapshot: KripkeStatePropertyList,
        calls: [Call],
        afterCalls: Set<Duration>
    ) {
        self.timeslot = timeslot
        self.before = before
        self.after = after
        self.transitioned = transitioned
        self.preSnapshot = preSnapshot
        self.postSnapshot = postSnapshot
        self.calls = calls
        self.afterCalls = afterCalls
    }

}

extension Ringlet: Hashable {

    static func == (lhs: Ringlet, rhs: Ringlet) -> Bool {
        lhs.transitioned == rhs.transitioned
        && lhs.preSnapshot == rhs.preSnapshot
        && lhs.postSnapshot == rhs.postSnapshot
        && lhs.calls == rhs.calls
        && lhs.afterCalls == rhs.afterCalls
        && lhs.timeslot == rhs.timeslot
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(transitioned)
        hasher.combine(preSnapshot)
        hasher.combine(postSnapshot)
        hasher.combine(calls)
        hasher.combine(afterCalls)
        hasher.combine(timeslot)
    }

}

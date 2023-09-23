import KripkeStructure

/// A data structure for representing a point in time to generate a node in the
/// Kripke structure.
enum VerificationStep: Hashable {

    /// Generate a separate Kripke structure for the given timeslots.
    case startDelegates(timeslots: Set<Timeslot>)

    /// Fetch the results of the generation for the separate Kripke structure
    /// with the given timeslots.
    case endDelegates(timeslots: Set<Timeslot>)

    /// Take an environment snapshot for the given timeslots.
    case takeSnapshot(timeslots: Set<Timeslot>)

    /// Take a snapshot and start executing the given timeslot.
    case takeSnapshotAndStartTimeslot(timeslot: Timeslot)

    /// Mark the start of a timeslot that we are not executing for this Kripke
    /// structure.
    case startTimeslot(timeslot: Timeslot)

    /// Execute the given timeslot.
    case execute(timeslot: Timeslot)

    /// Execute the given timeslot, and save an environment snapshot once
    /// executed.
    case executeAndSaveSnapshot(timeslot: Timeslot)

    /// Save an environment snapshot for the given timeslots.
    case saveSnapshot(timeslots: Set<Timeslot>)

    /// Should we take an environment snapshot?
    var takeSnapshot: Bool {
        switch self {
        case .takeSnapshot, .takeSnapshotAndStartTimeslot:
            return true
        default:
            return false
        }
    }

    /// Should we save an environment snapshot?
    var saveSnapshot: Bool {
        switch self {
        case .saveSnapshot, .executeAndSaveSnapshot:
            return true
        default:
            return false
        }
    }

    /// Should we start a timeslot?
    var startTimeslot: Bool {
        switch self {
        case .startTimeslot, .takeSnapshotAndStartTimeslot:
            return true
        default:
            return false
        }
    }

    /// The marker that distinguishes the type of node we are creating.
    var marker: String {
        switch self {
        case .takeSnapshot, .takeSnapshotAndStartTimeslot:
            return "R"
        case .startTimeslot, .startDelegates:
            return "S"
        case .execute, .endDelegates:
            return "E"
        case .executeAndSaveSnapshot, .saveSnapshot:
            return "W"
        }
    }

    /// The timeslots associated with this verification step.
    var timeslots: Set<Timeslot> {
        switch self {
        case .takeSnapshot(let timeslots),
            .saveSnapshot(let timeslots),
            .startDelegates(let timeslots),
            .endDelegates(let timeslots):
            return timeslots
        case .takeSnapshotAndStartTimeslot(let timeslot),
            .startTimeslot(let timeslot),
            .execute(let timeslot),
            .executeAndSaveSnapshot(let timeslot):
            return [timeslot]
        }
    }

    /// A set of executable id's associated with this timeslot.
    var executables: Set<Int> {
        Set(timeslots.map(\.callChain.executable))
    }

    /// Represent this step as a `KripkeStateProperty`.
    ///
    /// - Parameter state: The name of the state that we are currently executing
    /// in this step if available.
    ///
    /// - Parameter collapseIfPossible: Collapse the KripkeStateProperty into
    /// a single string property when possible, otherwise, the returned
    /// KripkeStateProperty will be a compound type.
    ///
    /// - Returns: A `KripkeStateProperty` representing this step.
    func property(state: String?, collapseIfPossible: Bool) -> KripkeStateProperty {
        let executables = self.executables
        if let first = executables.first, executables.count == 1 && collapseIfPossible {
            return KripkeStateProperty(
                type: .String,
                value: String(first) + "." + (state.map { $0 + "." } ?? "") + marker
            )
        } else {
            let marker = self.marker
            let names = executables.sorted().map(String.init)
            let value: [String: Any] = [
                "step": marker,
                "fsms": names,
                "state": state as Any
            ]
            let plist: [String: KripkeStateProperty] = [
                "step": KripkeStateProperty(marker),
                "fsms": KripkeStateProperty(
                    type: .Collection(names.map { KripkeStateProperty($0) }),
                    value: names
                ),
                "state": KripkeStateProperty(
                    type: .Optional(state.map { KripkeStateProperty(type: .String, value: $0) }),
                    value: state as Any
                )
            ]
            return KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(properties: plist)),
                value: value
            )
        }
    }

}

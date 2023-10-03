struct VerificationMap {

    struct Step: Hashable {

        var time: Duration

        var step: VerificationStep

    }

    private(set) var steps: SortedCollection<Step>

    var delegates: Set<String>

    init(steps: [Step], delegates: Set<String>) {
        self.steps = SortedCollection(unsortedSequence: steps) {
            if $0.time == $1.time {
                return .orderedSame
            } else if $0.time < $1.time {
                return .orderedAscending
            } else {
                return .orderedDescending
            }
        }
        self.delegates = delegates
    }

    mutating func handleFinishedCall(_ call: Call) {
        replaceSteps {
            guard $0.callChain.executable == call.callee.id else {
                return $0
            }
            var new = $0
            new.callChain.pop()
            return new
        }
    }

    mutating func handleCall(_ call: Call) {
        switch call.method {
        case .synchronous:
            handleSyncCall(call)
        case .asynchronous:
            handleASyncCall(call)
        }
    }

    private mutating func handleSyncCall(_ call: Call) {
        replaceSteps {
            guard $0.callChain.executable == call.caller.id else {
                return $0
            }
            var new = $0
            new.callChain.add(call)
            return new
        }
    }

    private mutating func handleASyncCall(_ call: Call) {
        replaceSteps {
            guard $0.callChain.root == call.callee.id else {
                return $0
            }
            guard $0.callChain.calls.isEmpty else {
                fatalError("Attempting to call callee that is currently already executing.")
            }
            var new = $0
            new.callChain.add(call)
            return new
        }
    }

    private mutating func replaceSteps(_ transform: (Timeslot) throws -> Timeslot) rethrows {
        var newSteps = Array(steps)
        for (index, step) in steps.enumerated() {
            switch step.step {
            case .takeSnapshot(let timeslots),
                .saveSnapshot(let timeslots),
                .startDelegates(let timeslots),
                .endDelegates(let timeslots):
                let newTimeslots: Set<Timeslot> = try Set(timeslots.map(transform))
                let newStep: VerificationStep
                switch step.step {
                case .takeSnapshot:
                    newStep = .takeSnapshot(timeslots: newTimeslots)
                case .saveSnapshot:
                    newStep = .saveSnapshot(timeslots: newTimeslots)
                case .startDelegates:
                    newStep = .startDelegates(timeslots: newTimeslots)
                case .endDelegates:
                    newStep = .endDelegates(timeslots: newTimeslots)
                default:
                    fatalError("Attempting to assign new timeslots to a step that is not supported")
                }
                newSteps[index] = Step(time: step.time, step: newStep)
            case .execute(let timeslot),
                .executeAndSaveSnapshot(let timeslot),
                .startTimeslot(let timeslot),
                .takeSnapshotAndStartTimeslot(let timeslot):
                let new = try transform(timeslot)
                let newStep: VerificationStep
                switch step.step {
                case .execute:
                    newStep = .execute(timeslot: new)
                case .executeAndSaveSnapshot:
                    newStep = .executeAndSaveSnapshot(timeslot: new)
                case .startTimeslot:
                    newStep = .startTimeslot(timeslot: new)
                default:
                    newStep = .takeSnapshotAndStartTimeslot(timeslot: new)
                }
                newSteps[index] = Step(time: step.time, step: newStep)
            }
        }
        self.steps = SortedCollection(sortedArray: newSteps, comparator: self.steps.comparator)
    }

    func hasFinished(forPool pool: ExecutablePool) -> Bool {
        let executables: Set<Int> = Set(steps.lazy.flatMap { (step: Step) -> Set<Int> in
            switch step.step {
            case .startDelegates, .endDelegates:
                return []
            default:
                return step.step.executables
            }
        })
        // return !pool.parameterisedFSMs.values.contains { $0.status == .executing }
        // && !fsms.contains { !pool.fsm($0).hasFinished }
        return !executables.contains {
            let element = pool.executables[pool.index(of: $0)]
            return !element.executable.isFinished(context: element.context)
        }
    }

}

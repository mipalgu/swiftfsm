import FSM

/// Provides a way to access a collection of executables that have been
/// classified by their function within a schedule.
public struct ExecutablePool {

    /// The type to differentiate executable id's.
    typealias ExecutableID = Int

    // struct ParameterisedStatus: DataStructure, CustomReflectable {

    //     enum Status: String, DataStructure {

    //         case inactive
    //         case executing

    //     }

    //     struct CallData: Hashable, Sendable {

    //         var parameters: [String: any DataStructure]

    //         var result: (any DataStructure)?

    //     }

    //     var customMirror: Mirror {
    //         Mirror(
    //             self,
    //             children: [
    //                 "status": status as Any,
    //                 "parameters": call?.parameters ?? Optional<any DataStructure>.none as Any,
    //                 "result": call?.result ?? Optional<(any DataStructure)?>.none as Any
    //             ],
    //             displayStyle: .struct,
    //             ancestorRepresentation: .suppressed
    //         )
    //     }

    //     var status: Status

    //     var call: CallData?

    // }

    // var parameterisedFSMs: [String: ParameterisedStatus]

    /// All executables within this pool.
    private(set) var executables: [ExecutableType]

    /// A mapping from the id of an executable to the index within
    /// `executables`.
    private var indexes: [ExecutableID: Int]

    /// Create a new pool.
    ///
    /// - Parameter executables: The executables within this pool.
    ///
    /// - Parameter indexes: A mapping from the id of an executable to the
    /// index within the executables parameter.
    private init(
        executables: [ExecutableType],
        indexes: [ExecutableID: Int]// ,
        // parameterisedFSMs: [String: ParameterisedStatus]) {
    ) {
        self.executables = executables
        self.indexes = indexes
        // self.parameterisedFSMs = parameterisedFSMs
    }

    // swiftlint:disable line_length

    /// Create a new pool from a collection of executables and their associated
    /// metadata.
    ///
    /// - Parameter executables: A sequence of executables, associated with
    /// their metadata.
    ///
    /// - Complexity: O(log(n)), where n is the number of elements in
    /// executables.
    init<S: Sequence>(executables: S) where S.Element == (FSMInformation, ExecutableType) {// , parameterisedFSMs: Set<String>) {
        let sorted = executables.sorted { $0.0.id < $1.0.id }
        self.init(
            executables: sorted.map(\.1),
            indexes: Dictionary(uniqueKeysWithValues: sorted.enumerated().map { ($1.0.id, $0) })// ,
            // parameterisedFSMs: Dictionary(uniqueKeysWithValues: parameterisedFSMs.map {
            //     ($0, ParameterisedStatus(status: .inactive, call: nil))
            // })
        )
    }

    // swiftlint:enable line_length

    /// Insert a new executable into the pool.
    ///
    /// - Parameter executable: The executable to add to the pool.
    ///
    /// - Parameter information: The metadata associated with the executable,
    /// including the executable unique identifier.
    ///
    /// - Attention: If there exists an executable with the same id, then the
    /// new executable will overwrite the old.
    mutating func insert(_ executable: ExecutableType, information: FSMInformation) {
        guard let index = indexes[information.id] else {
            let index = executables.count
            executables.append(executable)
            indexes[information.id] = index
            return
        }
        executables[index] = executable
    }

    /// Does an executable with the given id exist within this pool?
    ///
    /// - Parameter id: The id of the executable we are querying.
    func has(_ id: ExecutableID) -> Bool {
        indexes[id] != nil
    }

    /// Does an executable with the given id exist within this pool, and does
    /// that executable execute without having any parent executable
    /// dependencies?
    ///
    /// - Parameter id: The id of the executable we are querying.
    func hasThatIsntDelegate(_ id: ExecutableID) -> Bool {
        // if parameterisedFSMs[name] != nil {
        //     return false
        // }
        has(id)
    }

    /// Fetch the underlying index of an executable within this pool.
    ///
    /// - Parameter id: The id of the executable we are searching for.
    ///
    /// - Warning: If an executable with the given id cannot be found within
    /// this pool, this function causes a crash.
    func index(of id: ExecutableID) -> Int {
        guard let index = indexes[id] else {
            print(id)
            print(indexes)
            fatalError("Attempting to fetch index of executable that doesn't exist within the pool.")
        }
        return index
    }

    /// Fetches the executable at the given index.
    ///
    /// - Parameter index: The underlying index where the executable exists
    /// within the pool.
    ///
    /// - Returns: The executable at the given index.
    ///
    /// - Complexity: O(1)
    func executable(atIndex index: Int) -> ExecutableType {
        executables[index]
    }

    /// Fetches the executable with the given id.
    ///
    /// - Parameter id: The id of the executable to search within this pool.
    ///
    /// - Returns: The executable with the given id.
    ///
    /// - Warning: If an executable with the given id does not exist within
    /// this pool, then this causes a crash.
    func executable(_ id: ExecutableID) -> ExecutableType {
        executable(atIndex: index(of: id))
    }

    // swiftlint:disable line_length

    // func setPromises(_ promises: [String: PromiseData]) -> [PromiseSnapshot] {
    //     var setPromises: [PromiseSnapshot] = []
    //     setPromises.reserveCapacity(promises.count)
    //     for (callee, promise) in promises {
    //         guard let status = parameterisedFSMs[callee], status.status == .inactive, let call = status.call else {
    //             continue
    //         }
    //         let snapshot = PromiseSnapshot(promiseData: promise)
    //         setPromises.append(snapshot)
    //         promise._hasFinished = true
    //         promise.result = call.result
    //     }
    //     return setPromises
    // }

    // func undoSetPromises(_ promises: [PromiseSnapshot]) {
    //     for promise in promises {
    //         promise.apply()
    //     }
    // }

    // func propertyList(forStep step: VerificationStep, executingState state: String?, promises: [String: PromiseData], resetClocks: Set<String>?, collapseIfPossible collapse: Bool = false) -> KripkeStatePropertyList {
    //     let setPromises = setPromises(promises)
    //     var fsmValues: [String: KripkeStateProperty] = Dictionary(uniqueKeysWithValues: fsms.compactMap {
    //         guard !parameterisedFSMs.keys.contains($0.name) else {
    //             return nil
    //         }
    //         return ($0.name, KripkeStateProperty(type: .Compound(KripkeStatePropertyList($0.asScheduleableFiniteStateMachine.base)), value: $0.asScheduleableFiniteStateMachine.base))
    //     })
    //     fsmValues.reserveCapacity(fsmValues.count + parameterisedFSMs.count)
    //     for (key, val) in parameterisedFSMs {
    //         guard val.status == .executing, let call = val.call else {
    //             fsmValues[key] = KripkeStateProperty(type: .Optional(nil), value: Optional<[String: Any]>.none as Any)
    //             continue
    //         }
    //         fsmValues[key] = KripkeStateProperty(
    //             type: .Optional(KripkeStateProperty(
    //                 type: .Compound(KripkeStatePropertyList([
    //                     "parameters": .init(
    //                         type: .Compound(KripkeStatePropertyList(call.parameters.mapValues { KripkeStateProperty($0 as Any) })),
    //                         value: call.parameters
    //                     ),
    //                     "result": KripkeStateProperty(call.result)
    //                 ])),
    //                 value: call
    //             )),
    //             value: Optional<ParameterisedStatus.CallData>.some(call) as Any
    //         )
    //     }
    //     undoSetPromises(setPromises)
    //     let clocks: KripkeStateProperty? = resetClocks.map { resetClocks in
    //         let values = Dictionary(uniqueKeysWithValues: Set(fsmValues.keys).union(Set(parameterisedFSMs.keys)).map {
    //             ($0, resetClocks.contains($0))
    //         })
    //         let props = values.mapValues {
    //             KripkeStateProperty(type: .Bool, value: $0)
    //         }
    //         return KripkeStateProperty(type: .Compound(KripkeStatePropertyList(properties: props)), value: values)
    //     }
    //     var dict = [
    //         "fsms": KripkeStateProperty(type: .Compound(KripkeStatePropertyList(properties: fsmValues)), value: fsmValues.mapValues(\.value)),
    //         "pc": step.property(state: state, collapseIfPossible: collapse)
    //     ]
    //     dict["resetClocks"] = clocks
    //     return KripkeStatePropertyList(properties: dict)
    // }

    // mutating func handleCall(to fsm: String, parameters: [String: Any?]) {
    //     var status = self.parameterisedFSMs[fsm] ?? ParameterisedStatus(
    //         status: .inactive,
    //         call: nil
    //     )
    //     guard status.status == .inactive else {
    //         fatalError("Detected call to fsm that is already executing.")
    //     }
    //     status.status = .executing
    //     status.call = ParameterisedStatus.CallData(parameters: parameters, result: nil)
    //     self.parameterisedFSMs[fsm] = status
    // }

    // mutating func handleFinishedCall(for fsm: String, result: Any?) {
    //     guard var status = self.parameterisedFSMs[fsm], status.status == .executing, status.call != nil else {
    //         fatalError("Detected finishing call to fsm that has not been executing.")
    //     }
    //     status.status = .inactive
    //     status.call?.result = result
    //     self.parameterisedFSMs[fsm] = status
    // }

    // mutating func setInactive(_ fsm: String) {
    //     self.parameterisedFSMs[fsm]?.status = .inactive
    //     self.parameterisedFSMs[fsm]?.call = nil
    // }

    // swiftlint:enable line_length

}

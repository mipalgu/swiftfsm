import FSM
import KripkeStructure

/// A data structure for representing a sequence of parameterised machine
/// synchronise invocations.
///
/// This data structure is useful to map the calls that an executable may make,
/// to determine when results should be generated within a verification.
struct CallChain: Hashable {

    /// Represents a single call within the chain.
    private struct CallID: Hashable {

        /// The id of the executable that was called.
        var callee: Int

        /// The value of the parameters that were passed during the call.
        var parameters: [Int: (any DataStructure)?]

        /// Compare for equality.
        ///
        /// - Parameter lhs: The left-hand-side of the equals operator.
        ///
        /// - Parameter rhs: The right-hand-side of the equals operator.
        ///
        /// - Returns: Whether `lhs` equals `rhs`.
        static func == (lhs: CallID, rhs: CallID) -> Bool {
            guard lhs.callee == rhs.callee, lhs.parameters.keys == rhs.parameters.keys else {
                return false
            }
            // swiftlint:disable:next line_length
            for key in lhs.parameters.keys where KripkeStatePropertyList(lhs.parameters[key]) != KripkeStatePropertyList(rhs.parameters[key]) {
                return false
            }
            return true
        }

        /// Add self to a `Hasher`.
        ///
        /// - Parameter hasher: The `Hasher` containing our hash.
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.callee)
            hasher.combine(KripkeStatePropertyList(self.parameters.sorted { $0.key < $1.key }))
        }

    }

    /// The id of the executable that is the root of the call chain.
    var root: Int

    /// A mapping between a specific call id and the index within `calls`.
    private var indexes: [CallID: Int]

    /// The ordered sequence of calls made within this chain.
    private(set) var calls: [Call]

    // swiftlint:disable implicitly_unwrapped_optional

    /// The id of the last call made.
    private var lastId: CallID!

    // swiftlint:enable implicitly_unwrapped_optional

    /// The id of the executable at the end of the call chain.
    var executable: Int {
        calls.last?.callee.id ?? root
    }

    /// Create a CallChain.
    ///
    /// - Parmaeter root: The id of the executable that is the root of the call
    /// chain.
    ///
    /// - Parameter indexes: A mapping between a specific call id and the index
    /// within `calls`.
    ///
    /// - Parameter calls: The ordered sequence of calls made within this chain.
    private init(root: Int, indexes: [CallID: Int], calls: [Call]) {
        self.root = root
        self.indexes = indexes
        self.calls = calls
        self.lastId = calls.last.map { CallID(callee: $0.callee.id, parameters: $0.parameters) }
    }

    /// Create a CallChain.
    ///
    /// - Parameter root: The id of the executable that is the root of the call
    /// chain (i.e. if no calls have been made, then the executable with this
    /// id is executing).
    ///
    /// - Parameter calls: The ordered sequence of calls made within this chain.
    init(root: Int, calls: [Call]) {
        let indexes = Dictionary(uniqueKeysWithValues: calls.enumerated().map {
            (CallID(callee: $1.callee.id, parameters: $1.parameters), $0)
        })
        self.init(root: root, indexes: indexes, calls: calls)
    }

    /// Add a call to the call chain.
    ///
    /// - Parameter call: The call to add at the end of the call chain. This
    /// effectively means that a new executable described by `call` is now
    /// executing.
    mutating func add(_ call: Call) {
        let id = CallID(callee: call.callee.id, parameters: call.parameters)
        if let index = indexes[id] {
            fatalError("Cyclic call detected: \(calls[index..<calls.count])")
        }
        indexes[id] = calls.count
        calls.append(call)
        lastId = id
    }

    /// Remove the last call made to the call chain.
    ///
    /// - Warning: If no calls have been made, then this function causes a
    /// crash.
    @discardableResult
    mutating func pop() -> Call {
        indexes[lastId] = nil
        return calls.removeLast()
    }

    /// Retrieve the executable that is currently executing within at the top
    /// of this call chain from within the given pool.
    ///
    /// - Parameter pool: The `ExecutablePool` containing the executables
    /// executing within this call chain.
    ///
    /// - Returns: The `ExecutableType` for the executable with the id
    /// `executable` from within `pool`.
    func executable(fromPool pool: ExecutablePool) -> ExecutableType {
        guard let last = calls.last else {
            return pool.executable(root)
        }
        return pool.executable(last.callee.id)
    }

}

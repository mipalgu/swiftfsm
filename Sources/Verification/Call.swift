import FSM
import KripkeStructure

/// A data structure for representing a single asynchronous or synchronous call
/// to an executable.
public struct Call {

    /// A data structure for representing the parameters passed during a call.
    fileprivate struct Parameters: Hashable {

        /// The values of the parameters passed during the call.
        var parameters: [Int: (any DataStructure)?]

        /// Compare for equality.
        static func == (lhs: Parameters, rhs: Parameters) -> Bool {
            KripkeStatePropertyList(lhs) == KripkeStatePropertyList(rhs)
        }

        /// Compute the hash.
        func hash(into hasher: inout Hasher) {
            hasher.combine(KripkeStatePropertyList(self))
        }

    }

    /// A enum representing the possible methods for making a call.
    public enum Method: String, RawRepresentable, Comparable, Codable, CaseIterable, Hashable, Sendable {

        /// The asynchronous method of calling a machine.
        ///
        /// This method means that an executable makes a call within it's
        /// timeslot (the caller) to a callee with a dedicated timeslot within
        /// the schedule.
        case asynchronous

        /// The synchronous method of calling a machine.
        ///
        /// This method means that an executable makes a call within it's
        /// timeslot (the caller), resulting in a second executable (the callee)
        /// replacing the caller within the timeslot.
        case synchronous

        /// Is `lhs` less than `rhs`?
        ///
        /// - Paramaeter lhs: The left-hand-side of the less-than operator.
        ///
        /// - Parameter rhs: The right-hand-side of the less-than operator.
        ///
        /// - Returns true when `lhs` is less than `rhs`.
        public static func < (lhs: Method, rhs: Method) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

    }

    /// Metadata associated with the caller.
    var caller: FSMInformation

    /// Metadata associated with the callee.
    var callee: FSMInformation

    /// The value of the parameters passed during the call.
    var parameters: [Int: (any DataStructure)?]

    /// The method of the call being made (i.e. was this an asynchronous or
    /// synchronous call?).
    var method: Method

    // var promiseData: PromiseData

    public init(
        caller: FSMInformation,
        callee: FSMInformation,
        parameters: [Int: (any DataStructure)?],
        method: Method
    ) {
        self.caller = caller
        self.callee = callee
        self.parameters = parameters
        self.method = method
    }

}

extension Call: Equatable {

    /// Compare for equality.
    public static func == (lhs: Call, rhs: Call) -> Bool {
        lhs.caller == rhs.caller
            && lhs.callee == rhs.callee
            && lhs.parameters.keys == rhs.parameters.keys
            && Parameters(parameters: lhs.parameters) == Parameters(parameters: rhs.parameters)
            && lhs.method == rhs.method
    }

}

extension Call: Hashable {

    /// Compute hash.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.caller)
        hasher.combine(self.callee)
        hasher.combine(Parameters(parameters: parameters))
        hasher.combine(self.method)
    }

}

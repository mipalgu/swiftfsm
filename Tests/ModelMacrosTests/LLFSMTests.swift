import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ModelMacros)
@testable import ModelMacros
#endif

final class LLFSMTests: XCTestCase {

    func test_generatesCorrectCode() throws {
        #if canImport(ModelMacros)
        let src = """
            @LLFSM
            public struct FSMMock {

                @Context
                public struct Context {

                    public var fsmCount: Int = 0

                }

                @EnvironmentSnapshot
                public struct Environment {

                    @WriteOnly
                    public var exitActuator: Bool!

                    @ReadWrite
                    public var exitExternalVariable: Bool!

                    @ReadWrite
                    public var exitGlobalVariable: Bool!

                    @ReadOnly
                    public var exitSensor: Bool!
                }

                @StateContext
                public struct PangData {

                    public var stateCount: Int = 0

                }

                @State(
                    name: "Ping",
                    onExit: { $0.fsmCount += 1 },
                    transitions: {
                        Transition(to: \\.$pong)
                    }
                )
                public var ping

                @State(
                    name: "Pong",
                    onExit: { $0.fsmCount += 1 },
                    transitions: {
                        Transition(to: \\.$pang)
                    }
                )
                public var pong

                @State(
                    name: "Pang",
                    initialContext: PangData(),
                    uses: \\.$exitSensor,
                    onEntry: { $0.stateCount = 0 },
                    internal: {
                        $0.stateCount += 1
                        $0.fsmCount += 1
                    },
                    transitions: {
                        Transition(to: \\.$exit, context: PangData.self) { $0.exitSensor }
                        Transition(to: "Ping", context: PangData.self) { $0.stateCount > 5 }
                    }
                )
                public var pang

                @State(name: "Exit", onEntry: { _ in print("Exit") })
                public var exit

                public let initialState = #state(\\.$ping)

                public init() {}

            }
            """
        let expected = """
            public struct FSMMock {

                @Context
                public struct Context {

                    public var fsmCount: Int = 0

                }

                @EnvironmentSnapshot
                public struct Environment {

                    @WriteOnly
                    public var exitActuator: Bool!

                    @ReadWrite
                    public var exitExternalVariable: Bool!

                    @ReadWrite
                    public var exitGlobalVariable: Bool!

                    @ReadOnly
                    public var exitSensor: Bool!
                }

                @StateContext
                public struct PangData {

                    public var stateCount: Int = 0

                }

                @State(
                    name: "Ping",
                    onExit: { $0.fsmCount += 1 },
                    transitions: {
                        Transition(to: \\.$pong)
                    }
                )
                public var ping

                @State(
                    name: "Pong",
                    onExit: { $0.fsmCount += 1 },
                    transitions: {
                        Transition(to: \\.$pang)
                    }
                )
                public var pong

                @State(
                    name: "Pang",
                    initialContext: PangData(),
                    uses: \\.$exitSensor,
                    onEntry: { $0.stateCount = 0 },
                    internal: {
                        $0.stateCount += 1
                        $0.fsmCount += 1
                    },
                    transitions: {
                        Transition(to: \\.$exit, context: PangData.self) { $0.exitSensor }
                        Transition(to: "Ping", context: PangData.self) { $0.stateCount > 5 }
                    }
                )
                public var pang

                @State(name: "Exit", onEntry: { _ in print("Exit") })
                public var exit

                public let initialState = #state(\\.$ping)

                public init() {}

            }

            public extension FSMMock: LLFSM {
            }
            """
        assertMacroExpansion(
            src,
            expandedSource: expected,
            macros: ["LLFSM": LLFSM.self]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


}

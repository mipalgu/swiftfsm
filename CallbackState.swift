//
//  CallbackState.swift
//  swiftfsm
//
//  Created by Callum McColl on 23/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class CallbackState: State {
    
    public private(set) var name: String
    
    public var transitions: [Transition]
    
    public let _onEntry: () -> Void
    public let _main: () -> Void
    public let _onExit: () -> Void
    
    public init(
        name: String,
        transitions: [Transition] = [],
        onEntry: () -> Void = {},
        main: () -> Void = {},
        onExit: () -> Void = {}
    ) {
        self.name = name
        self.transitions = transitions
        self._onEntry = onEntry
        self._main = main
        self._onExit = onExit
    }
    
    public func addTransition(transition: Transition) {
        self.transitions.append(transition)
    }
    
    public func onEntry() -> Void {
        return self._onEntry()
    }
    
    public func main() -> Void {
        return self._main()
    }
    
    public func onExit() -> Void {
        return self._onExit()
    }
    
}
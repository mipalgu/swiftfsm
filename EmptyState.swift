//
//  EmptyState.swift
//  swiftfsm
//
//  Created by Callum McColl on 11/08/2015.
//  Copyright (c) 2015 MiPal. All rights reserved.
//

/**
 *  A state that does nothing.
 */
public class EmptyState: State {
    
    private var _name: String
    private var _transitions: [Transition]
    
    public var name: String {
        return self._name
    }
    
    public var transitions: [Transition] {
        return self._transitions
    }
    
    public init(name: String, transitions: [Transition] = []) {
        self._name = name
        self._transitions = transitions
    }
    
    public func onEntry() -> Void {}
    public func main() -> Void {}
    public func onExit() -> Void {}
    
}
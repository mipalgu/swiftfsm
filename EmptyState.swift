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
    
    public private(set) var name: String
    
    public var transitions: [Transition]
    
    public init(name: String, transitions: [Transition] = []) {
        self.name = name
        self.transitions = transitions
    }
    
    public func addTransition(transition: Transition) {
        self.transitions.append(transition)
    }
    
    public func onEntry() -> Void {}
    public func main() -> Void {}
    public func onExit() -> Void {}
    
}
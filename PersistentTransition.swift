//
//  PersistentTransition.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class PersistentTransition: Transition {
    
    public private(set) var sourceState: State
    
    public private(set) var targetState: State
    
    public init(sourceState: State, targetState: State) {
        self.sourceState = sourceState
        self.targetState = targetState
    }
    
    public func canTransition() -> Bool {
        return true
    }
    
}
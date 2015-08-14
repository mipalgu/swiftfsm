//
//  PersistentTransition.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class PersistentTransition: Transition {
    
    private let _state: State
    
    public var state: State {
        return _state
    }
    
    public init(state: State) {
        self._state = state
    }
    
    public func canTransition() -> Bool {
        return true
    }
    
}
//
//  PersistentTransition.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class PersistentTransition: Transition {
    
    private let _sourceState: State
    private let _targetState: State
    
    public var sourceState: State {
        return _sourceState
    }
    
    public var targetState: State {
        return _targetState
    }
    
    public init(sourceState: State, targetState: State) {
        self._sourceState = sourceState
        self._targetState = targetState
    }
    
    public func canTransition() -> Bool {
        return true
    }
    
}
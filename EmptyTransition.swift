//
//  PersistentTransition.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class EmptyTransition: Transition {
    
    public let source: State
    
    public let target: State
    
    public init(source: State, target: State) {
        self.source = source
        self.target = target
    }
    
    public func canTransition() -> Bool {
        return true
    }
    
}
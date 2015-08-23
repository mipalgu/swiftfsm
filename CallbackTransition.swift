//
//  CallbackTransition.swift
//  swiftfsm
//
//  Created by Callum McColl on 23/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public struct CallbackTransition: Transition {
    
    public let source: State
    public let target: State
    private let _canTransition: () -> Bool
    
    public init(source: State, target: State, canTransition: () -> Bool = { return true }) {
        self.source = source
        self.target = target
        self._canTransition = canTransition
    }
    
    public func canTransition() -> Bool {
        return self._canTransition()
    }
    
}
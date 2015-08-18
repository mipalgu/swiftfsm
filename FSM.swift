//
//  FSM.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class FSM: FSMType {
    
    private let initialState: State
    
    private var currentState: State
    
    private let ringlet: Ringlet
    
    public init(initialState: State, ringlet: Ringlet) {
        self.initialState = initialState
        self.currentState = initialState
        self.ringlet = ringlet
    }
    
    public func exit() {
        self.currentState = ExitState(name: "_exit")
    }
    
    public func next() {
        self.currentState = self.ringlet.execute(self.currentState)
    }
    
    public func restart() {
        self.currentState = self.initialState
    }
    
    public func suspend() {
        self.currentState = SuspendState(name: "_suspend")
    }
    
}
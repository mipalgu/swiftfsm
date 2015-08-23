//
//  FSM.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class FSM: FiniteStateMachine {
    
    private let initialState: State
    
    private var currentState: State
    
    private let ringlet: Ringlet
    
    private var suspendedState: State?
    
    public init(initialState: State, ringlet: Ringlet) {
        self.initialState = initialState
        self.currentState = initialState
        self.ringlet = ringlet
    }
    
    public func exit() {
        self.currentState = ExitState(name: "_exit")
    }
    
    public func isSuspended() -> Bool {
        return self.suspendedState == nil
    }
    
    public func next() {
        if (self.suspendedState != nil) {
            return
        }
        self.currentState = self.ringlet.execute(self.currentState)
    }
    
    public func restart() {
        self.currentState = self.initialState
    }
    
    public func resume() {
        if (self.suspendedState == nil) {
            return
        }
        self.currentState = self.suspendedState!
        self.suspendedState = nil
    }
    
    public func suspend() {
        self.suspendedState = self.currentState
        self.currentState = SuspendState(name: "_suspend")
    }
    
}
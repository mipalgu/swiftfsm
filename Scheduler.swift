//
//  Scheduler.swift
//  swiftfsm
//
//  Created by Callum McColl on 18/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class Scheduler {
    
    private static var machines: [FiniteStateMachine] = []
    
    private(set) var machines: [FiniteStateMachine] {
        get {
            return Scheduler.machines
        } set {
            Scheduler.machines = newValue
        }
    }
    
    public init() {}
    
    public func addMachine(machine: FiniteStateMachine) -> Void {
        self.machines.append(machine)
    }
    
    public func run() -> Void {
        for var i: Int = 0; i < self.machines.count; i++ {
            self.machines[i].next()
            if (i >= self.machines.count - 1) {
                i = -1
            }
        }
    }
    
}
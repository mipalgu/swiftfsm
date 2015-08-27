//
//  Scheduler.swift
//  swiftfsm
//
//  Created by Callum McColl on 18/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//
import Swift_FSM

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
        // Just keep running and loop around when we reach the end of the array
        for (
            var i: Int = 0;
            i < self.machines.count;
            i = (i + 1) % self.machines.count
        ) {
            self.machines[i].next()
        }
    }
    
}
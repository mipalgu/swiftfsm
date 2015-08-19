//
//  Scheduler.swift
//  swiftfsm
//
//  Created by Callum McColl on 18/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class Scheduler {
    
    private static var machines: [FSMType] = []
    
    private(set) var machines: [FSMType] {
        get {
            return Scheduler.machines
        } set {
            Scheduler.machines = newValue
        }
    }
    
    public func addMachine(machine: FSMType) -> Void {
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
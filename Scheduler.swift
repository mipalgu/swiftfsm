//
//  Scheduler.swift
//  swiftfsm
//
//  Created by Callum McColl on 18/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class Scheduler {
    
    private static var machines: [FSMType] = []
    
    public func addMachine(machine: FSMType) -> Void {
        Scheduler.machines.append(machine)
    }
    
    public func run() -> Void {
        for var i: Int = 0; i < Scheduler.machines.count; i++ {
            Scheduler.machines[i].next()
            if (i >= Scheduler.machines.count - 1) {
                i = -1
            }
        }
    }
    
}
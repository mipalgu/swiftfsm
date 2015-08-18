//
//  Scheduler.swift
//  swiftfsm
//
//  Created by Callum McColl on 18/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class Scheduler {
    
    private static let _scheduler: Scheduler = Scheduler()
    
    private var machines: [FSMType] = []
    
    public func addMachine(machine: FSMType) -> Void {
        Scheduler._scheduler.machines.append(machine)
    }
    
    public func run() -> Void {
        for var i: Int = 0; i < Scheduler._scheduler.machines.count; i++ {
            Scheduler._scheduler.machines[i].next()
            if (i >= Scheduler._scheduler.machines.count - 1) {
                i = -1
            }
        }
    }
    
}
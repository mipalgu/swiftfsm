//
//  FSMType.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

/**
 *  A common interface for the operations that finite state machines can
 *  execute.
 */
public protocol FSMType {
    
    /**
     *  Execute the next state.
     */
    func next() -> Void
    
    /**
     *  Restart the finite state machine.
     */
    func restart() -> Void
    
    /**
     *  Suspend the finite state machine.
     */
    func suspend() -> Void
    
}
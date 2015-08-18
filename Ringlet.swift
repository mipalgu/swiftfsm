//
//  Ringlet.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

/**
 *  A way in which a state is executed.
 *
 *  A Ringlet is a series of steps which are taken in the execution of a state.
 *  In other words a Ringlet is responsible for calling the methods within a
 *  a state in a particular order.
 */
public protocol Ringlet {
    
    /**
     *  Execute a state.
     *
     *  This method returns the next state to execute.  If the execution of the
     *  state results in a transition then the new state is returned, otherwise
     *  the same state passed into this method is returned.
     */
    func execute(state: State) -> State
    
}
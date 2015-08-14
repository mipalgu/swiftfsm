//
//  Transition.swift
//  swiftfsm
//
//  Created by Callum McColl on 11/08/2015.
//  Copyright (c) 2015 MiPal. All rights reserved.
//

/**
 *  A transition which allows the current state to change from one state to the
 *  next.
 *  
 *  Transitions may have to meet certain conditions which is why the
 *  canTransition method returns a Bool indicating whether or not this specific
 *  transition is allowed.
 */
public protocol Transition {
    
    /**
     *  The state which we are transitioning to.
     */
    var state: State { get }
    
    /**
     *  Do we meet all of the conditions to transition?
     */
    func canTransition() -> Bool
    
}
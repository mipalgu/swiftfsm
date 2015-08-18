//
//  State.swift
//  swiftfsm
//
//  Created by Callum McColl on 11/08/2015.
//  Copyright (c) 2015 MiPal. All rights reserved.
//

/**
 *  A simple state.
 *
 *  Implement this protocol for any states that you wish to create within your
 *  machines.
 *
 *  The state executes in what is known as a Ringlet.  The three methods that
 *  are presented below are each executed independently within the ringlet.  See
 *  StandardRinglet for the standard order that these methods are executed in.
 */
public protocol State {
    
    /**
     *  A label in plain english for the state - must be unique per state.
     */
    var name: String { get }
    
    /**
     *  All transitions that are possible for the state.
     */
    var transitions: [Transition] { get }
    
    /**
     *  This method is called when the state is first transitioned into.
     */
    func onEntry() -> Void
    
    /**
     *  The main method is called if the state cannot transition to another
     *  state.
     *
     *  This method is the same as the internal method in other fsms.  The
     *  reason for changing this method to main is because internal is a keyword
     *  in swift and you are unable to use it as a function name.
     */
    func main() -> Void
    
    /**
     *  The onExit method is called when the machine is transitioning out of the
     *  this state.
     */
    func onExit() -> Void
    
}

/**
 *  Use a states names hashValue by default for Hashability.
 *
 *  This is required for using states as keys in dictionaries.
 */
extension State where Self: Hashable {
    
    var hashValue: Int {
        return name.hashValue
    }
    
}

/**
 *  Compare states names for equality by default.
 */
public func ==(lhs: State, rhs: State) -> Bool {
    return lhs.name == rhs.name
}

/**
 *  Make states printable and debug printable by default.
 */
extension State where
    Self: CustomStringConvertible,
    Self: CustomDebugStringConvertible
{
    
    public var description: String {
        return name
    }
    
    public var debugDescription: String {
        return description
    }
    
}
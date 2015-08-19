//
//  StandardRinglet.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

/**
 *  A standard ringlet.
 *
 *  Firstly calls onEntry if this state has just been transitioned into.  If a
 *  transition is possible then the states onExit method is called and the new
 *  state is returned.  If no transitions are possible then the main method is
 *  called and the state is returned.
 */
public class StandardRinglet: Ringlet {
    
    /**
     *  Set as the last state that was executed.
     */
    private var oldState: State?
    
    public init() {}
    
    /**
     *  Execute the ringlet.
     *
     *  Returns a state representing the next state to execute.
     */
    public func execute(state: State) -> State {
        // Call onEntry if the state has just been transitioned into.
        if (false == self.isOldState(state)) {
            state.onEntry()
        }
        // Remember that we have already executed this state.
        self.oldState = state
        // Can we transition to another state?
        let s: State? = self.transition(state.transitions)
        if (s != nil) {
            // Yes - Exit state and return the new state.
            state.onExit()
            return s!
        }
        // No - Execute main method and return state.
        state.main()
        return state
    }
    
    /*
     *  Check the state to see if it is the same as oldState.
     */
    private func isOldState(state: State) -> Bool {
        if (self.oldState == nil) {
            return false
        }
        return state == self.oldState!
    }
    
    /*
     *  Check all transitions and return the state that we can transition to.
     *
     *  Returns the state that can be transitioned into or nil if no transitions
     *  can be found.
     */
    private func transition(transitions: [Transition]) -> State? {
        // Check all transitions
        for t: Transition in transitions {
            if (false == t.canTransition()) {
                continue
            }
            // Found transition
            return t.targetState
        }
        // No transitions possible
        return nil
    }
    
}
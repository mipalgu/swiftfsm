//
//  main.swift
//  swiftfsm
//
//  Created by Rene Hexel on 14/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

import Darwin
import Swift_FSM

print("Hello, when I grow up, I will be a full-blown state machine scheduler!")
    
var states: [State] = [
    CallbackState(name: "ping", onEntry: {print("ping")}),
    CallbackState(name: "pong", onEntry: {print("pong")})
]
    
var transitions: [Transition] = [
    EmptyTransition(source: states[0], target: states[1]),
    EmptyTransition(source: states[1], target: states[0])
]
    
states[0].addTransition(transitions[0])
states[1].addTransition(transitions[1])
    
let fsm: FiniteStateMachine = FSM(
    initialState: states[0],
    ringlet: StandardRinglet()
)

let scheduler: Scheduler = Scheduler()
scheduler.addMachine(fsm)
scheduler.run()
//
//  main.swift
//  swiftfsm
//
//  Created by Rene Hexel on 14/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

import Darwin

print("Hello, when I grow up, I will be a full-blown state machine scheduler!")

var states: [State] = [
    PingState(name: "ping"),
    PongState(name: "pong")
]

var transitions: [Transition] = [
    PersistentTransition(sourceState: states[0], targetState: states[1]),
    PersistentTransition(sourceState: states[1], targetState: states[0])
]

states[0].attachTransition(transitions[0])
states[1].attachTransition(transitions[1])

var fsm: FSMType = FSM(
    initialState: states[0],
    ringlet: StandardRinglet()
)

let scheduler: Scheduler = Scheduler()
scheduler.addMachine(fsm)
scheduler.run()
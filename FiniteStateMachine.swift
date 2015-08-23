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
public protocol FiniteStateMachine:
    Exitable,
    Restartable,
    StateExecuter,
    Suspendable
{}
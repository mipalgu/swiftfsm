//
//  PongState.swift
//  swiftfsm
//
//  Created by Callum McColl on 12/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

import Swift_FSM

public class PongState: EmptyState {
    
    public override func onEntry() {
        print("pong\n")
    }
    
}
//
//  MachineLoader.swift
//  swiftfsm
//
//  Created by Callum McColl on 19/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

import Darwin
import Swift_FSM

protocol MachineLoader {
    
    func load(name: String) -> FSMType?
    
}
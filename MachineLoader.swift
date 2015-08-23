//
//  MachineLoader.swift
//  swiftfsm
//
//  Created by Callum McColl on 19/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

import SwiftFSM

protocol MachineLoader {
    
    func load(name: String) -> FSMType?
    
}
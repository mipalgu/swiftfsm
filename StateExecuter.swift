//
//  StateExecuter.swift
//  swiftfsm
//
//  Created by Callum McColl on 23/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public protocol StateExecuter {
    
    mutating func next() -> State
    
}
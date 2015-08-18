//
//  Transitionable.swift
//  swiftfsm
//
//  Created by Callum McColl on 18/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public protocol Transitionable {
    
    var transitions: [Transition] { get }
    
    func attachTransition(transition: Transition) -> Void
    
}
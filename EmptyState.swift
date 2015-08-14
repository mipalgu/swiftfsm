//
//  EmptyState.swift
//  swiftfsm
//
//  Created by Callum McColl on 11/08/2015.
//  Copyright (c) 2015 MiPal. All rights reserved.
//

/**
 *  A state that does nothing.
 */
public class EmptyState: State {
    
    private var _name: String
    
    public var name: String {
        return self._name
    }
    
    public init(name: String) {
        self._name = name
    }
    
    public func onEntry() -> Void {}
    public func main() -> Void {}
    public func onExit() -> Void {}
    
}
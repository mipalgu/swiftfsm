//
//  DLMachineLoader.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

import Swift_FSM

public class LibraryMachineLoader: MachineLoader {
    
    private let manager: LibraryManager
    
    public init(manager: LibraryManager) {
        self.manager = manager
    }
    
    public func load(path: String) -> FiniteStateMachine? {
        let lib: LibraryResource? = self.manager.open(path)
        if lib == nil {
            return nil
        }
        let result: (UnsafeMutablePointer<Void>, String?) =
            lib!.getSymbolPointer("start")
        if (result.1 != nil) {
            print(result.1)
            return nil
        }
        let f: () -> FiniteStateMachine = result.0.memory as () -> FiniteStateMachine
        return f()
    }
    
}
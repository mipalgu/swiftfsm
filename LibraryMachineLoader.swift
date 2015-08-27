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
    
    public func load(path: String) -> [FiniteStateMachine] {
        let lib: LibraryResource? = self.manager.open(path)
        if lib == nil {
            return []
        }
        let result: (symbol: UnsafeMutablePointer<Void>, error: String?) =
            lib!.getSymbolPointer("start")
        if (result.error != nil) {
            print(result.error)
            return []
        }
        let f: UnsafeMutablePointer<() -> [FiniteStateMachine]> =
            UnsafeMutablePointer<() -> [FiniteStateMachine]>(result.symbol)
        return f.memory()
    }
    
}
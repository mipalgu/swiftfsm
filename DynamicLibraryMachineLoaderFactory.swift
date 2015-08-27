//
//  DynamicLibraryMachineLoaderFactory.swift
//  swiftfsm
//
//  Created by Callum McColl on 27/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class DynamicLibraryMachineLoaderFactory: MachineLoaderFactory {
    
    public func make() -> MachineLoader {
        return LibraryMachineLoader(
            manager: ReferenceCountingLibraryManager(
                creator: DynamicLibraryCreator()
            )
        )
    }
    
}
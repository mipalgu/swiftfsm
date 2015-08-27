//
//  DynamicLibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class DynamicLibraryCreator: LibraryCreator {
    
    public func open(path: String) -> LibraryResource? {
        let handler: UnsafeMutablePointer<Void> = dlopen(path, RTLD_NOW)
        if (handler == nil) {
            return nil
        }
        return DynamicLibraryResource(handler: handler, path: path)
    }
    
}
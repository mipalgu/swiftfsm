//
//  DynamicLibraryResource.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class DynamicLibraryResource: LibraryResource {
    
    let handler: UnsafeMutablePointer<Void>
    
    public init(handler: UnsafeMutablePointer<Void>) {
        self.handler = handler
    }
    
    public func getSymbolPointer(symbol: String) -> (
        UnsafeMutablePointer<Void>,
        error: String?
    ) {
        let symbol: UnsafeMutablePointer<Void> = dlsym(self.handler, symbol)
        if (symbol != nil) {
            return (symbol, error: nil)
        }
        return (symbol, error: String.fromCString(dlerror()))
    }
    
}
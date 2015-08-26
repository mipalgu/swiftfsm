//
//  DynamicLibraryResource.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class DynamicLibraryResource: LibraryResource {
    
    public let path: String
    
    private let handler: UnsafeMutablePointer<Void>
    
    public init(path: String, handler: UnsafeMutablePointer<Void>) {
        self.path = path
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
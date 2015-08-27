//
//  DynamicLibraryResource.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class DynamicLibraryResource: LibraryResource {
    
    private let handler: UnsafeMutablePointer<Void>
    public let path: String
    
    
    public init(handler: UnsafeMutablePointer<Void>, path: String) {
        self.handler = handler
        self.path = path
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
    
    public func close() -> (successful: Bool, error: String?) {
        let result: CInt = dlclose(self.handler)
        if (result == 0) {
            return (successful: true, error: nil)
        }
        return (successful: false, error: String.fromCString(dlerror()))
    }
    
}
//
//  LibraryResource.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public protocol LibraryResource {
    
    func getSymbolPointer(symbol: String) -> (
        UnsafeMutablePointer<Void>,
        error: String?
    )
    
    func close()

}
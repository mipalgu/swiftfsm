//
//  LibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 27/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public protocol LibraryManager: LibraryCreator {
    
    func close(library: LibraryResource)
    
}
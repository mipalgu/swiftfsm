//
//  LibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public protocol LibraryManager {
    
    func open(path: String) -> LibraryResource?
    func close(resource: LibraryResource)
    
}

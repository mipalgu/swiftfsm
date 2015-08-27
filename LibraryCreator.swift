//
//  LibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public protocol LibraryCreator {
    
    func open(path: String) -> LibraryResource?
    
}

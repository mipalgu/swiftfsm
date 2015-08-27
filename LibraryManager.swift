//
//  LibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 27/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class LibraryManager: LibraryCreator {
    
    private static var libraries[String: UInt] = [:]
    
    private var libraries {
        get {
            return LibraryManager.libraries
        } set {
            LibraryManager.libraries = newValue
        }
    }
    
    private let creator: LibraryCreator
    
    public init(creator: LibraryCreator) {
        self.creator = creator
    }
    
    public func open(path: String) -> LibraryResource? {
        if (self.libraries[path] == nil) {
            self.libraries[path] = 0
        }
        let resource: LibraryResource? = self.creator.open(path)
        if (resource == nil) {
            return nil
        }
        self.libraries[path]!++
        return resource
    }
    
    public func close(library: LibraryResource) {
        library.close()
        if (self.libraries[library.path] == nil) {
            self.libraries[library.path] = 0
            return
        }
        if (self.libraries[library.path]! == 0) {
            return
        }
        self.libraries[library.path]!--
        
    }
    
}
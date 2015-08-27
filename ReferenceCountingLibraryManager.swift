//
//  LibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 27/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class ReferenceCountingLibraryManager: LibraryCreator {
    
    private static var libraries: [String: UInt] = [:]
    
    private var libraries: [String: UInt] {
        get {
            return ReferenceCountingLibraryManager.libraries
        } set {
            ReferenceCountingLibraryManager.libraries = newValue
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
        // This should never happen.
        if (self.libraries[library.path] == nil) {
            self.libraries[library.path] = 0
        }
        // Decrement reference count.
        if (self.libraries[library.path]! > 0) {
            self.libraries[library.path]!--
        }
        // Close if reference count reaches 0
        if (self.libraries[library.path] == 0) {
            self.closeLibrary(library)
        }
    }
    
    private func closeLibrary(library: LibraryResource) {
        let result = library.close()
        if (result.successful) {
            return
        }
        if (result.error == nil) {
            return
        }
        print(result.error)
    }
    
}
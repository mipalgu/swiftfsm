//
//  DynamicLibraryManager.swift
//  swiftfsm
//
//  Created by Callum McColl on 26/08/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

public class DynamicLibraryCreator: LibraryCreator {

    private var libraries: [String: UInt8] = [:]
    
    public func open(path: String) -> LibraryResource? {
        if (self.libraries[path] == nil) {
            self.libraries[path] = 0
        }
        let handler: UnsafeMutablePointer<Void> = dlopen(path, RTLD_NOW)
        if (handler == nil) {
            return nil
        }
        self.libraries[path]!++
        return DynamicLibraryResource(handler: handler, path: path)
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
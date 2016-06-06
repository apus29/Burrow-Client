//
//  Resolver.swift
//  Burrow
//
//  Created by Jaden Geller on 5/29/16.
//
//

// Records what callbacks our future is obligated to notify once the value is resolved
internal class Resolver<Element> {
    internal typealias Callback = Element -> ()
    
    private var obligations: [Callback] = []
    private var value: Element?
}

extension Resolver {
    internal func register(callback: Callback){
        if let value = value {
            callback(value)
        } else {
            obligations.append(callback)
        }
    }
    
    internal func resolve(with value: Element) {
        guard self.value == nil else {
            fatalError("An obligation must only be resolved once.")
        }
        
        // Record value for future obligations
        self.value = value
        
        // Resolve existing obligations
        for callback in obligations {
            callback(value)
        }
        
        // Clear list of obligations
        obligations.removeAll(keepCapacity: false)
    }
}

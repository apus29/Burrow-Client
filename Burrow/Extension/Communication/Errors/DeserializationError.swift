//
//  DeserializationError.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

import Foundation

public struct DeserializationError: ErrorType {
    public enum Code: String {
        case invalidMessageFormat = "Invalid Message Format"
        case invalidMessageContents = "Invalid Message Contents"
    }
    
    public var code: Code
    public var reason: String?
    public var object: NSObject?
    
    init(code: Code, reason: String? = nil, object: NSObject? = nil) {
        self.code = code
        self.reason = reason
        self.object = object
    }
}

extension DeserializationError: CustomStringConvertible {
    public var description: String {
        var result = "DeserializationError(code: \(code.rawValue.debugDescription)"
        if let reason = reason { result += ", reason: \(reason.debugDescription)" }
        if let object = object { result += ", object: \(object.debugDescription)" }
        result += ")"
        return result
    }
}

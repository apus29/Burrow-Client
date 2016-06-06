//
//  ServerError.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

import Foundation

public struct ServerError: ErrorType {
    public enum Code: String {
        case unknownError = "Unknown Error"
        case unknownMessageType = "Unknown Message Type"
        case unknownSessionIdentifier = "Unknown Session Identifier"
        case undefinedError = "Undefined Error"
        
        init(_ rawValue: Int) {
            switch rawValue {
            case 0:  self = .unknownError
            case 1:  self = .unknownMessageType
            case 2:  self = .unknownSessionIdentifier
            default: self = .undefinedError
            }
        }
    }
    
    public var code: Code
    public var reason: String?
    public var object: String?
    
    init(code: Code, reason: String? = nil, object: String? = nil) {
        self.code = code
        self.reason = reason
        self.object = object
    }
}

extension ServerError: CustomStringConvertible {
    public var description: String {
        var result = "ServerError(code: \(code.rawValue.debugDescription)"
        if let reason = reason { result += ", reason: \(reason.debugDescription)" }
        if let object = object { result += ", object: \(object.debugDescription)" }
        result += ")"
        return result
    }
}
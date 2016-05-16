//
//  ShovelError.swift
//  Burrow
//
//  Created by Jaden Geller on 4/18/16.
//
//

public struct ShovelError: ErrorType {
    public enum Code: String {
        case unexpectedRecordType = "Unexpected record type."
        case unexpectedRecordFormat = "Unexpected record format."
        case unexpectedServerResponse = "Unexpected server response."
        case serverErrorResponse = "Server error response."
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

extension ShovelError: CustomStringConvertible {
    public var description: String {
        var result = "ShovelError(code: \(code.rawValue.debugDescription)"
        if let reason = reason { result += ", reason: \(reason.debugDescription)" }
        if let object = object { result += ", object: \(object.debugDescription)" }
        result += ")"
        return result
    }
}


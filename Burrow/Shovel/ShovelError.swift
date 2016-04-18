//
//  ShovelError.swift
//  Burrow
//
//  Created by Jaden Geller on 4/18/16.
//
//

struct ShovelError: ErrorType {
    enum Code: String {
        case unexpectedRecordType = "Unexpected record type."
        case unexpectedRecordFormat = "Unexpected record format."
        case unexpectedServerResponse = "Unexpected server response."
        case serverErrorResponse = "Server error response."
    }
    
    var code: Code
    var reason: String?
    var object: NSObject?
    
    init(code: Code, reason: String? = nil, object: NSObject? = nil) {
        self.code = code
        self.reason = reason
        self.object = object
    }
}

extension ShovelError: CustomStringConvertible {
    var description: String {
        var result = "ShovelError(code: \(code.rawValue.debugDescription)"
        if let reason = reason { result += ", reason: \(reason.debugDescription)" }
        if let object = object { result += ", object: \(object.debugDescription)" }
        result += ")"
        return result
    }
}

public enum Result<Element> {
    case Success(Element)
    case Failure(ErrorType)
}

extension Result {
    public init(_ closure: () throws -> Element) {
        do {
            self = .Success(try closure())
        } catch let error {
            self = .Failure(error)
        }
    }
    
    public func value() throws -> Element {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
}

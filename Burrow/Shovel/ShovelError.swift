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
    
    init(code: Code, reason: String? = nil) {
        self.code = code
        self.reason = reason
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

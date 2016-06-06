//
//  Result.swift
//  Burrow
//
//  Created by Jaden Geller on 5/9/16.
//
//

public protocol ResultType {
    associatedtype Element
    init(@noescape _ closure: () throws -> Element)
    func unwrap() throws -> Element
}

public enum Result<Element>: ResultType {
    case Success(Element)
    case Failure(ErrorType)
}

extension Result {
    public init(@noescape _ closure: () throws -> Element) {
        do {
            self = .Success(try closure())
        } catch let error {
            self = .Failure(error)
        }
    }
    
    public func unwrap() throws -> Element {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
    
    public var error: ErrorType? {
        switch self {
        case .Success:
            return nil
        case .Failure(let error):
            return error
        }
    }
}

extension Result {
    public func map<V>(@noescape transform: (Element) throws -> V) -> Result<V> {
        switch self {
        case .Success(let value):
            do {
                return .Success(try transform(value))
            } catch let error {
                return .Failure(error)
            }
        case .Failure(let error):
            return .Failure(error)
        }
    }
    
    public mutating func mutate(@noescape mutation: (inout Element) throws -> ()) {
        if case .Success(let value) = self {
            do {
                var copy = value
                try mutation(&copy)
                self = .Success(copy)
            } catch let error {
                self = .Failure(error)
            }
        }
    }
    
    public func recover(@noescape handle: (ErrorType) throws -> Element) -> Result<Element> {
        switch self {
        case .Success(let value):
            return .Success(value)
        case .Failure(let error):
            do {
                return .Success(try handle(error))
            } catch let error {
                return .Failure(error)
            }
        }
    }
}

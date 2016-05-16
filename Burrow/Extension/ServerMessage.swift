//
//  ServerMessage.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

import Foundation

enum ServerMessage {
    case beginSession(SessionIdentifier)
    case forwardPacket
    case requestPacket(NSData)
    case endSession
}

extension ServerMessage {
    init(type: MessageType, deserializing string: String) throws {
        var components = string.characters.split("-").map{ String($0) }.generate()
        let success: Bool = try Bool(deserializing: try components.next(failure: "Missing type", object: string))
        
        if success {
            switch type {
            case .beginSession:
                let sessionIdentifier = try components.next(failure: "Missing session identifier", object: string)
                self = .beginSession(SessionIdentifier(sessionIdentifier))
            case .forwardPacket:
                self = .forwardPacket
            case .requestPacket:
                let packetDataString = try components.next(failure: "Missing packet data", object: string)
                self = .requestPacket(try NSData(deserializing: packetDataString))
            case .endSession:
                self = .endSession
            }
        } else {
            let code = try Int(deserializing: components.next(failure: "Missing error code", object: string))
            let reason = try components.next(failure: "Missing reason", object: string)
            let object = try components.next(failure: "Missing object", object: string)
            
            throw ServerError(
                code: ServerError.Code(code),
                reason: reason.isEmpty ? nil : reason,
                object: object.isEmpty ? nil : object
            )
        }
    }
    
    init(type: MessageType, deserializing data: NSData) throws {
        self = try ServerMessage(type: type, deserializing: String(data: data, encoding: NSUTF8StringEncoding)!)
    }
}

// Mark: Helpers

extension NSData {
    private convenience init(deserializing string: String) throws {
        guard let packetData = NSData(base64EncodedString: string, options: []) else {
            throw DeserializationError(
                code: .invalidMessageContents,
                reason: "Expected base64 encoded data.",
                object: string
            )
        }
        self.init(data: packetData)
    }
}

extension Bool {
    private init(deserializing string: String) throws {
        switch string {
        case "t": self = true
        case "f": self = false
        default: throw DeserializationError(
            code: .invalidMessageContents,
            reason: "Expected success or failure token.",
            object: string
            )
        }
    }
}

extension Int {
    private init(deserializing string: String) throws {
        guard let value = Int(string) else {
            throw DeserializationError(
                code: .invalidMessageContents,
                reason: "Expected integer error code.",
                object: string
            )
        }
        self = value
    }
}

extension GeneratorType {
    private mutating func next(failure message: String, object: String) throws -> Element {
        guard let value = self.next() else {
            throw DeserializationError(
                code: .invalidMessageFormat,
                reason: message,
                object: object
            )
        }
        return value
    }
}


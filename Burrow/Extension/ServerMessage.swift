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
    case forwardPackets
    case requestPackets([NSData])
    case endSession
}

extension ServerMessage {
    init(type: MessageType, deserializing string: String) throws {
        // anyGenerator gives us reference semantics so we consume the generator
        // when we create an array with the remaining elements
        // TODO: Is this inefficient?
        var components = AnyGenerator(string.characters.split("-").map{ String($0) }.generate())
        let success: Bool = try Bool(deserializing: try components.next(failure: "Missing type", object: string))
        
        if success {
            switch type {
            case .beginSession:
                let sessionIdentifier = try components.next(failure: "Missing session identifier", object: string)
                self = .beginSession(SessionIdentifier(sessionIdentifier))
            case .forwardPackets:
                self = .forwardPackets
            case .requestPackets:
                let packetsDataStrings = Array(components)
                self = .requestPackets(try packetsDataStrings.map(NSData.init(deserializing:)))
            case .endSession:
                self = .endSession
            }
            
            let remaining = Array(components)
            guard remaining.isEmpty else {
                throw DeserializationError(
                    code: .invalidMessageFormat,
                    reason: "Too many components in server message.",
                    object: [
                        "type_identifier" : type.identifier,
                        "message" : string
                    ] as NSDictionary
                )
            }
            
        } else {
            let code = try Int(deserializing: components.next(failure: "Missing error code", object: string))
            let reason = try components.next(failure: "Missing reason", object: string)
            
            // TODO: Decide if the object is required. Right now, the server is misbehaved.
            let object = components.next() //try components.next(failure: "Missing object", object: string)
            
            precondition(components.next() == nil)

            throw ServerError(
                code: ServerError.Code(code),
                reason: reason.isEmpty ? nil : reason,
                object: object//.isEmpty ? nil : object
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
        case "s": self = true
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


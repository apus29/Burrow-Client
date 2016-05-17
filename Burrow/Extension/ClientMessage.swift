//
//  ClientMessage.swift
//  Burrow
//
//  Created by Jaden Geller on 4/24/16.
//
//

import Foundation

enum ClientMessage {
    case beginSession
    case forwardPackets(SessionIdentifier, [NSData])
    case requestPackets(SessionIdentifier)
    case endSession(SessionIdentifier)
}

extension String {
    init(serializing message: ClientMessage) {
        let arguments: [String] = {
            switch message {
            case .beginSession:
                return []
            case .forwardPackets(let sessionIdentifier, let packets):
                return [String(sessionIdentifier)] + packets.map{ $0.base64EncodedStringWithOptions([]) }
            case .requestPackets(let identifier):
                return [String(identifier)]
            case .endSession(let identifier):
                return [String(identifier)]
            }
        }()
        self = ([message.type.identifier] + arguments).joinWithSeparator("-")
    }
}


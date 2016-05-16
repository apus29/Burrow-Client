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
    case forwardPacket(SessionIdentifier, NSData)
    case requestPacket(SessionIdentifier)
    case endSession(SessionIdentifier)
}

extension String {
    init(serializing message: ClientMessage) {
        let components: [String] = {
            switch message {
            case .beginSession:
                return ["b"]
            case .forwardPacket(let identifier, let packet):
                return ["f", String(identifier), packet.base64EncodedStringWithOptions([])]
            case .requestPacket(let identifier):
                return ["r", "-", String(identifier)]
            case .endSession(let identifier):
                return ["e", String(identifier)]
            }
        }()
        self = components.joinWithSeparator("-")
    }
}


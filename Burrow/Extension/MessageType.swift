//
//  MessageType.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

enum MessageType {
    case beginSession
    case forwardPacket
    case requestPacket
    case endSession
}

extension ClientMessage {
    var type: MessageType {
        switch self {
        case .beginSession:  return .beginSession
        case .forwardPacket: return .forwardPacket
        case .requestPacket: return .requestPacket
        case .endSession:    return .endSession
        }
    }
}

extension ServerMessage {
    var type: MessageType {
        switch self {
        case .beginSession:  return .beginSession
        case .forwardPacket: return .forwardPacket
        case .requestPacket: return .requestPacket
        case .endSession:    return .endSession
        }
    }
}

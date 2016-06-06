//
//  MessageType.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

enum MessageType {
    case beginSession
    case forwardPackets
    case requestPackets
    case endSession
}

extension MessageType {
    var identifier: String {
        switch self {
        case .beginSession:
            return "b"
        case .forwardPackets:
            return "f"
        case .requestPackets:
            return "r"
        case .endSession:
            return "e"
        }
    }
}

extension ClientMessage {
    var type: MessageType {
        switch self {
        case .beginSession:  return .beginSession
        case .forwardPackets: return .forwardPackets
        case .requestPackets: return .requestPackets
        case .endSession:    return .endSession
        }
    }
}

extension ServerMessage {
    var type: MessageType {
        switch self {
        case .beginSession:  return .beginSession
        case .forwardPackets: return .forwardPackets
        case .requestPackets: return .requestPackets
        case .endSession:    return .endSession
        }
    }
}

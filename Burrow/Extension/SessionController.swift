//
//  SessionController.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

import Shovel

extension TransmissionManager {
    func send(message: ClientMessage, responseHandler: Result<ServerMessage> -> ()) {
        // TODO: Don't double encode the data. It's inefficient.
        transmit(domainSafeMessage: String(serializing: message)) { response in
            response.map { responseData in
                try ServerMessage(type: message.type, deserializing: responseData)
            }
        }
    }
}

class SessionController {
    
    // MARK: Initialization
    
    private let transmissionManager: TransmissionManager
    init(domain: Domain) {
        self.transmissionManager = TransmissionManager(domain: domain)
    }
    
    // MARK: Properties
    
    private var sessionIdentifier: SessionIdentifier?

    var running: Bool {
        return sessionIdentifier != nil
    }
    
    // MARK: Functions
    
    func beginSession(completion: (Result<()>) -> ()) {
        precondition(!running)
        transmissionManager.send(.beginSession) { result in
            completion(result.map { response in
                guard case .beginSession(let identifier) = response else { fatalError() }
                self.sessionIdentifier = identifier
            }.recover { error in
                // TODO: Recover from certain kinds of failures
                throw error
            })
        }
    }
    
    func forwardPacket(packet: NSData, completion: (Result<()>) -> ()) {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        transmissionManager.send(.forwardPacket(identifier, packet)) { result in
            completion(result.map { response in
                guard case .forwardPacket = response else { fatalError() }
            }.recover { error in
                // TODO: Recover from certain kinds of failures
                throw error
            })
        }
    }
    
    func requestPacket(completion: (Result<NSData>) -> ()) {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        transmissionManager.send(.requestPacket(identifier)) { result in
            completion(result.map { response in
                guard case .requestPacket(let packet) = response else { fatalError() }
                return packet
            }.recover { error in
                // TODO: Recover from certain kinds of failures
                throw error
            })
        }
    }
    
    func endSesssion(completion: (Result<()>) -> ()) {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        transmissionManager.send(.endSession(identifier)) { result in
            completion(result.map { response in
                guard case .endSession = response else { fatalError() }
            })
        }
    }

}


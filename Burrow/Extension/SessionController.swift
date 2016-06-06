//
//  SessionController.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

import Shovel

import Logger
extension Logger { public static let sessionControllerCategory = "SessionController" }
private let log = Logger.category(Logger.sessionControllerCategory)

extension TransmissionManager {
    func send(message: ClientMessage) throws -> Future<Result<ServerMessage>> {
        log.debug("Will send message: \(message)")
        
        // TODO: Don't double encode the data. It's inefficient.
        return try transmit(domainSafeMessage: String(serializing: message)).mapSuccess { responseData in
            log.info("Sent message: \(message)")
            return try ServerMessage(type: message.type, deserializing: responseData)
        }
    }
}

protocol SessionControllerDelegate: class {
    func handleReceived(packets packets: Result<[NSData]>)
}

class SessionController {
    
    // MARK: Initialization
    
    private let transmissionManager: TransmissionManager
    init(domain: Domain) {
        self.transmissionManager = TransmissionManager(domain: domain)
    }
    
    // MARK: Properties
    private var sessionIdentifier: SessionIdentifier?
    
    weak var delegate: SessionControllerDelegate?

    var running: Bool {
        return sessionIdentifier != nil
    }
    
    // MARK: Functions
    
    func beginSession() throws -> Future<Result<()>> {
        log.precondition(!running)
        // TODO: Recover from certain kinds of failures
        return try transmissionManager.send(.beginSession).mapSuccess { response in
            guard case .beginSession(let identifier) = response else { fatalError() }
            self.sessionIdentifier = identifier
            self.poll()
        }
    }
    
    func forward(packets packets: [NSData]) throws -> Future<Result<()>> {
        log.debug("Will forward \(packets.count) packets=")
        log.verbose("Will forward packets: \(packets)")
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        // TODO: Recover from certain kinds of failures
        return try transmissionManager.send(.forwardPackets(identifier, packets)).mapSuccess { response in
            guard case .forwardPackets = response else { fatalError() } // TODO: Maybe throw an error...
            log.debug("Successfully forwarded \(packets.count) packets=")
            log.verbose("Successfully forwarded packets: \(packets)")
        }
    }
    
    // TODO: On failure, retry.
    // Requests packets from the server, and repeats once packets have been received.
    private func poll() {
        log.verbose("Polling for packets...")
        log.caught { try request().then { packets in
            if case let .Success(packets) = packets {
                log.debug("Received \(packets.count) packets")
                log.verbose("Received: \(packets)")
            }
            self.delegate?.handleReceived(packets: packets)
            if self.running { self.poll() }
        } }
    }
    
    private func request() throws -> Future<Result<[NSData]>> {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        // TODO: Recover from certain kinds of failures
        return try transmissionManager.send(.requestPackets(identifier)).mapSuccess { response in
            guard case .requestPackets(let packets) = response else { fatalError() }
            return packets
        }
    }
    
    func endSesssion() throws -> Future<Result<()>> {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        return try transmissionManager.send(.endSession(identifier)).mapSuccess { response in
            guard case .endSession = response else { fatalError() }
        }
    }

}


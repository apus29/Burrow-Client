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
    func send(message: ClientMessage, responseHandler: Result<ServerMessage> -> ()) {
        log.debug("Will send message: \(message)")
        
        // TODO: Don't double encode the data. It's inefficient.
        transmit(domainSafeMessage: String(serializing: message)) { response in
            responseHandler(response.map { responseData in
                log.info("Sent message: \(message)")
                return try ServerMessage(type: message.type, deserializing: responseData)
            })
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
    
    func beginSession(completion: (Result<()>) -> ()) {
        precondition(!running)
        transmissionManager.send(.beginSession) { result in
            completion(result.map { response in
                guard case .beginSession(let identifier) = response else { fatalError() }
                self.sessionIdentifier = identifier
                self.poll()
            }.recover { error in
                // TODO: Recover from certain kinds of failures
                throw error
            })
        }
    }
    
    func forward(packets packets: [NSData], completion: (Result<()>) -> ()) {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        transmissionManager.send(.forwardPackets(identifier, packets)) { result in
            completion(result.map { response in
                guard case .forwardPackets = response else { fatalError() }
            }.recover { error in
                // TODO: Recover from certain kinds of failures
                throw error
            })
        }
    }
    
    // TODO: Do we really need a queue? We will have 1 thread, I think :P
    static let pollQueue = dispatch_queue_create("SessionController", DISPATCH_QUEUE_CONCURRENT)
    
    private func poll() {
        log.verbose("Polling for packets...")

        // TODO: Worry about synchronization issues where running is set to false.
        // TODO: Should any of this shit be weak?
        request { packets in
            if case let .Success(packets) = packets {
                log.debug("Received \(packets.count) packets")
                log.verbose("Received: \(packets)")
            }
            self.delegate?.handleReceived(packets: packets)
            if self.running { self.poll() }
        }
    }
    
    private func request(completion: (packets: Result<[NSData]>) -> ()) {
        guard let identifier = sessionIdentifier else { preconditionFailure() }
        transmissionManager.send(.requestPackets(identifier)) { result in
            completion(packets: result.map { response in
                guard case .requestPackets(let packets) = response else { fatalError() }
                return packets
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


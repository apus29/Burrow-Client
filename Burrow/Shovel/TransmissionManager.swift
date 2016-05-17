//
//  Transmission.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import Foundation

public struct TransmissionManager {
    public let domain: Domain
    
    public init(domain: Domain) {
        self.domain = domain
    }
}

private func value(from attributes: [String : String], forExpectedKey key: String) throws -> String {
    guard let value = attributes[key] else {
        throw ShovelError(code: .unexpectedServerResponse, reason: "Response missing \"\(key)\" key.")
    }
    return value
}

private func requireSuccess(expectedValue: String, from attributes: [String : String]) throws {
    let foundValue = try value(from: attributes, forExpectedKey: "success")
    precondition(["True", "False"].contains(foundValue))
    guard foundValue == "True" else {
        throw ShovelError(code: .serverErrorResponse, reason: attributes["error"])
    }
}

private func requireValue(expectedValue: String, from attributes: [String : String], forExpectedKey key: String, object: NSObject? = nil) throws {
    let foundValue = try value(from: attributes, forExpectedKey: key)
    guard foundValue == expectedValue else {
        throw ShovelError(code: .unexpectedServerResponse, reason: "Expected \"\(expectedValue)\" value for \"\(key)\" key. Found \"\(foundValue)\".", object: object)
    }
}

extension TransmissionManager {
    private static let queue = dispatch_queue_create("TransmissionManager", DISPATCH_QUEUE_CONCURRENT)
}

extension TransmissionManager {
    internal func begin() throws -> String {
        let message = try ServerMessage.withQuery(
            domain: domain.prepending("begin").prepending(NSUUID().UUIDString),
            recordClass: .internet,
            recordType: .txt,
            useTCP: true,
            bufferSize: 4096
        )
        let attributes = try TXTRecord.parseAttributes(message.value)

        try requireValue("True", from: attributes, forExpectedKey: "success")
        let transmissionId = try value(from: attributes, forExpectedKey: "transmission_id")

        return transmissionId
    }
    
    internal func end(transmissionId: String, count: Int) throws -> String {
        let message = try ServerMessage.withQuery(
            domain: domain.prepending("end").prepending(transmissionId).prepending(String(count)),
            recordClass: .internet,
            recordType: .txt,
            useTCP: true,
            bufferSize: 4096
        )
        let attributes = try TXTRecord.parseAttributes(message.value)
        // TODO: Also print transmission id on failure?
        try requireValue("True", from: attributes, forExpectedKey: "success", object: [
            "transmissionId" : transmissionId,
            "message" : message
        ] as NSDictionary)

        return try value(from: attributes, forExpectedKey: "contents")
    }
    
    internal func transmit(domainSafeMessage message: String) throws -> String {
        let transmissionId = try begin()
        
        let continueDomain = domain.prepending("continue").prepending(transmissionId)
        let domains = DomainPackagingMessage(domainSafeMessage: message, underDomain: { index in
            continueDomain.prepending(String(index))
        })

        let group = dispatch_group_create()
        var count = 0
        for domain in domains {
            count += 1
            // TODO: MAKE ASYNC
//            dispatch_group_aync(group, TransmissionManager.queue) {
                func sendMessage() {
                    do {
                        let message = try ServerMessage.withQuery(
                            domain: domain,
                            recordClass: .internet,
                            recordType: .txt,
                            useTCP: true,
                            bufferSize: 4096
                        )
                        let attributes = try TXTRecord.parseAttributes(message.value)
                        try requireValue("True", from: attributes, forExpectedKey: "success")
                    } catch let error {
                        // TODO: Handle more elegantly by passing the error back up, somehow.
                        fatalError("Failed data transfer: \(error)")
                        // Try again?
                        // TODO: Limit number of tries
                        // TODO: what if the failure is bad format?
//                        sendMessage()
                    }
                }
                
                // TODO: Barf
                sendMessage()
//            }
        }
        
        // TODO: Should we have a timeout in case the server ceases to exist or something?
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        // TODO: Waiting to send this might be adding significat delays.
        do {
            let response = try end(transmissionId, count: count)
            return response
        } catch {
            // TODO: This catch shoudln't be here! At least not a catch all. Adding
            // to test if it fixes something...
            // TODO: Shouldn't retry infinite times...
            print("Failed transmit, so trying again...")
            return try transmit(domainSafeMessage: message)
        }
    }
    
    public func transmit(domainSafeMessage message: String, responseHandler: Result<String> -> ()) {
        // TODO: MAKE ASYNC
        dispatch_async(TransmissionManager.queue) {
            responseHandler(Result {
                try self.transmit(domainSafeMessage: message)
            })
        }
    }
}
//
//  Transmission.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import Foundation
import Logger

extension Logger { public static let transmissionCategory = "Transmission" }
private let log = Logger.category(Logger.transmissionCategory)

let transmissionTimeout: Int64 = 20 // seconds

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
    
    internal func begin(responseHandler: Result<String> -> ()) throws {
        log.debug("Attempting to begin tranmission...")
        
        let beginDomain = domain.prepending("begin").prepending(NSUUID().UUIDString)
        try DNSResolver.resolveTXT(beginDomain) { result in
            responseHandler(result.map{ txtRecords in
                let attributes = try TXTRecord.parse(attributes: txtRecords)
                
                try requireValue("True", from: attributes, forExpectedKey: "success")
                let transmissionId = try value(from: attributes, forExpectedKey: "transmission_id")
                
                log.info("Began transmission with id \(transmissionId)")
                return transmissionId
            })
        }
    }
    
    internal func end(transmissionId: String, count: Int, responseHandler: Result<String> -> ()) throws {
        log.debug("Attempting to end tranmission with id \(transmissionId), count \(count)...")

        let endDomain = domain.prepending("end").prepending(transmissionId).prepending(String(count))
        try DNSResolver.resolveTXT(endDomain) { result in
            responseHandler(result.map { txtRecords in
                let attributes = try TXTRecord.parse(attributes: txtRecords)

                // TODO: Also print transmission id on failure?
                try requireValue("True", from: attributes, forExpectedKey: "success", object: [
                    "transmissionId" : transmissionId,
                    "attributes" : attributes
                ] as NSDictionary)
                let contents = try value(from: attributes, forExpectedKey: "contents")
                
                log.info("Ended tranmission with id \(transmissionId)")
                return contents
            })
        }
    }
    
    /// Send a domain-safe message to the server and asynchronously receive the response, or an error on failure
    public func transmit(domainSafeMessage message: String, responseHandler: Result<String> -> ()) throws {
        log.verbose("Attempting to transmit message: \(message)")
        // TODO: Could we improve speed by reducing the RTT required to start and end a transmission?
        // TODO: The control flow here is more confusing than I'd like. It's not obvious how to fix it.
        
        // Begin transmission
        try begin { result in
            do {
                let transmissionId = try result.unwrap()
                
                // Encode message as a sequence of domains
                let continueDomain = self.domain.prepending("continue").prepending(transmissionId)
                let domains = Array(DomainPackagingMessage(domainSafeMessage: message, underDomain: { index in
                    continueDomain.prepending(String(index))
                }))
                
                // Use a semaphore to ensure we wait until all records are resolved
                let finished = dispatch_semaphore_create(domains.count)
                
                // Send payload of our message
                var failures: [ErrorType] = []
                for domain in domains {
                    try DNSResolver.resolveTXT(domain) { result in
                        do {
                            let txtRecords = try result.unwrap()
                            let attributes = try TXTRecord.parse(attributes: txtRecords)
                            
                            // Verify success
                            try requireValue("True", from: attributes, forExpectedKey: "success")
                            log.verbose("Continued tranmission with id \(transmissionId), index \(domains.count)...")
                            
                        } catch let error {
                            
                            // Record failure
                            failures.append(error)
                            log.error("Failed to continue tranmission with id \(transmissionId), index \(domains.count): \(error)")
                        }
                        dispatch_semaphore_signal(finished)
                    }
                }
                
                // Wait until all the continues are sent, throwing an error on timeout
                let failureTime = dispatch_time(DISPATCH_TIME_NOW, transmissionTimeout * 10_000_000_000)
                let status = dispatch_semaphore_wait(finished, failureTime)
                guard status == 0 else {
                    throw ShovelError(
                        code: .transmissionTimeout,
                        reason: "Exceeded \(transmissionTimeout) second timeout for sending payload.",
                        object: [
                            "message" : message,
                            "transmissionId" : transmissionId
                        ]
                    )
                }
                guard failures.isEmpty else {
                    throw ShovelError(
                        code: .payloadFailure,
                        reason: "Failed to transmit payload.",
                        object: [
                            "message" : message,
                            "transmissionId" : transmissionId,
                            "payloadFailures" : failures.map { "\($0)" }
                        ]
                    )
                }
                log.debug("Transmitted entire message for id \(transmissionId)")
                
                // Let the server know that the transmission is finished
                try self.end(transmissionId, count: domains.count) { result in
                    responseHandler(Result {
                        let response = try result.unwrap()
                        
                        log.info("Successfully completed transmission for id \(transmissionId)")
                        log.debug("Received response for id \(transmissionId): \(response)")
                        
                        return response
                    })
                }
            }
            catch let error {
                // Propagate error through the response handler
                responseHandler(.Failure(error))
            }
        }
    }
}
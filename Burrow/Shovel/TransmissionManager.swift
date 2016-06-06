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
    log.precondition(["True", "False"].contains(foundValue))
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
    
    internal func begin() throws -> Future<Result<String>> {
        log.debug("Attempting to begin tranmission...")
        
        let beginDomain = domain.prepending("begin").prepending(NSUUID().UUIDString)
        return try DNSResolver.resolveTXT(beginDomain).mapSuccess { txtRecords in
            let attributes = try TXTRecord.parse(attributes: txtRecords)
            
            try requireValue("True", from: attributes, forExpectedKey: "success")
            let transmissionId = try value(from: attributes, forExpectedKey: "transmission_id")
            
            log.info("Began transmission with id \(transmissionId)")
            return transmissionId
        }
    }
    
    internal func end(transmissionId: String, count: Int) throws -> Future<Result<String>> {
        log.debug("Attempting to end tranmission with id \(transmissionId), count \(count)...")

        let endDomain = domain.prepending("end").prepending(transmissionId).prepending(String(count))
        return try DNSResolver.resolveTXT(endDomain).mapSuccess { txtRecords in
            let attributes = try TXTRecord.parse(attributes: txtRecords)
            
            // TODO: Also print transmission id on failure?
            try requireValue("True", from: attributes, forExpectedKey: "success", object: [
                "transmissionId" : transmissionId,
                "attributes" : attributes
            ] as NSDictionary)
            let contents = try value(from: attributes, forExpectedKey: "contents")
            
            log.info("Ended tranmission with id \(transmissionId)")
            return contents
        }
    }
    
    /// Send a domain-safe message to the server and asynchronously receive the response, or an error on failure
    public func transmit(domainSafeMessage message: String) throws -> Future<Result<String>> {
        log.verbose("Attempting to transmit message: \(message)")
        // TODO: Could we improve speed by reducing the RTT required to start and end a transmission?
        // TODO: The control flow here is more confusing than I'd like. It's not obvious how to fix it.

        return try begin().flatMapSuccess { transmissionId in
            // Encode message as a sequence of domains
            let continueDomain = self.domain.prepending("continue").prepending(transmissionId)
            let domains = Array(DomainPackagingMessage(domainSafeMessage: message, underDomain: { index in
                continueDomain.prepending(String(index))
            }))
            log.verbose("Will send \(domains.count) continue messages for tranmission with id \(transmissionId)")

            // TODO: It'd be nice to support waiting until a timeout.
            return try Future.awaiting(allOf: domains.map { domain in
                try DNSResolver.resolveTXT(domain).mapSuccess { txtRecords in
                    let attributes = try TXTRecord.parse(attributes: txtRecords)
                    
                    // Verify success
                    try requireValue("True", from: attributes, forExpectedKey: "success")
                    log.verbose("Continued tranmission with id \(transmissionId), index \(domains.count)...")
                }
            }).map { results in
                return Result {
                    // TODO: This is gross.
                    let failures = results.filter { $0.error != nil }.map { $0.error! }

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
                    
                    return
                }
            }.flatMap { _ in
                // Let the server know that the transmission is finished
                do {
                    return try self.end(transmissionId, count: domains.count).mapSuccess { response in
                        log.info("Successfully completed transmission for id \(transmissionId)")
                        log.verbose("Received response for id \(transmissionId): \(response)")
                        
                        return response
                    }
                } catch let error {
                    return Future(value: .Failure(error))
                }
            }
        }
    }
}
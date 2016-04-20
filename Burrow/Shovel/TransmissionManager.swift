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

private func requireValue(expectedValue: String, from attributes: [String : String], forExpectedKey key: String) throws {
    let foundValue = try value(from: attributes, forExpectedKey: key)
    guard foundValue == expectedValue else {
        throw ShovelError(code: .unexpectedServerResponse, reason: "Expected \"\(expectedValue)\" value for \"\(key)\" key. Found \"\(foundValue)\".")
    }
}

extension TransmissionManager {
    private static let queue = dispatch_queue_create("TransmissionManager", DISPATCH_QUEUE_CONCURRENT)
}

extension TransmissionManager {
    private func begin() throws -> String {
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
    
    private func end(transmissionId: String, count: Int) throws -> NSData {
        let message = try ServerMessage.withQuery(
            domain: domain.prepending("end").prepending(transmissionId).prepending(String(count)),
            recordClass: .internet,
            recordType: .txt,
            useTCP: true,
            bufferSize: 4096
        )
        let attributes = try TXTRecord.parseAttributes(message.value)
        try requireValue("True", from: attributes, forExpectedKey: "success")

        let contents = try value(from: attributes, forExpectedKey: "contents")
        guard let data = NSData(base64EncodedString: contents, options: []) else {
            throw ShovelError(
                code: .unexpectedServerResponse,
                reason: "Unable to decode contents as Base64.",
                object: contents
            )
        }
        return data
    }
    
    private func transmit(data: NSData) throws -> NSData {
        let transmissionId = try begin()
        
        let continueDomain = domain.prepending("continue").prepending(transmissionId)
        let domains = TransmissionManager.package(data, underDomain: { index in
            continueDomain.prepending(String(index))
        })

        let group = dispatch_group_create()
        for domain in domains {
            dispatch_group_async(group, TransmissionManager.queue) {
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
                }
            }
        }
        
        // TODO: Should we have a timeout in case the server ceases to exist or something?
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        // TODO: Waiting to send this might be adding significat delays.
        let response = try end(transmissionId, count: domains.count)
        return response
    }
    
    public func transmit(data: NSData, responseHandler: Result<NSData> -> ()) {
        dispatch_async(TransmissionManager.queue) {
            responseHandler(Result {
                try self.transmit(data)
            })
        }
    }
}

extension TransmissionManager {
    internal static func package(data: NSData, underDomain domain: (index: Int) -> Domain) -> [Domain] {
        let data = data.base64EncodedStringWithOptions([]).utf8
        var dataIndex = data.startIndex
        
        // In each iteration of the loop, build a single domain and add it to the array.
        var domains: [Domain] = []
        var countIndex = 0
        while dataIndex != data.endIndex {
            defer { countIndex += 1 }
            
            // Get the correct parent domain.
            var domain = domain(index: countIndex)
            let level = domain.level
            
            // In each iteration, append a data label to the domain
            // looping while there is still data to append and space to append it
            while true {
                let nextLabelLength = min(
                    domain.maxNextLabelLength,
                    dataIndex.distanceTo(data.endIndex)
                )
                guard nextLabelLength > 0 else { break }
                
                // From the length, compute the end index
                let labelEndIndex = dataIndex.advancedBy(nextLabelLength)
                defer { dataIndex = labelEndIndex }
                
                // Prepend the component
                domain.prepend(String(data[dataIndex..<labelEndIndex]), atLevel: level)
            }
            
            domains.append(domain)
        }
        
        return domains
    }
}

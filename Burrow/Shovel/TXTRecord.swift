//
//  DNS.swift
//  Burrow
//
//  Created by Jaden Geller on 4/10/16.
//
//

import CResolver
import Foundation

struct TXTRecord {
    var contents: String
}

extension TXTRecord {
    var attribute: (key: String, value: String)? {
        let components = contents.characters.split("=", maxSplit: 1)
        guard components.count == 2 else { return nil }
        return (key: String(components[0]), value: String(components[1]))
    }
}

extension TXTRecord {
    static func parse(attributes records: [TXTRecord]) throws -> [String : String] {
        var result: [String : String] = [:]
        for record in records {
            guard let (key, value) = record.attribute else {
                throw ShovelError(
                    code: .unexpectedRecordFormat,
                    reason: "Expected RFC 1464 format.",
                    object: record.contents
                )
            }
            result[key] = value
        }
        return result
    }
}

extension String {
    init?(baseAddress: UnsafePointer<CChar>, length: Int, encoding: NSStringEncoding) {
        let data = NSData(bytes: baseAddress, length: length)
        guard let string = String(data: data, encoding: encoding) else { return nil }
        self = string
    }
}

extension TXTRecord {
    init?(buffer: UnsafeBufferPointer<UInt8>) {
        var contents = ""
        var componentIndex = buffer.startIndex
        while componentIndex < buffer.endIndex {
            let componentLength = Int(buffer[componentIndex])
            let componentBase = buffer.baseAddress.advancedBy(componentIndex + 1)
            
            contents += String(
                baseAddress: UnsafePointer(componentBase),
                length: componentLength,
                encoding: NSUTF8StringEncoding
            )!
            
            componentIndex += Int(1 + componentLength)
        }
        
        self.init(contents: contents)
    }
}

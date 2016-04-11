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

extension String {
    init?(baseAddress: UnsafePointer<CChar>, length: Int, encoding: NSStringEncoding) {
        let data = NSData(bytes: baseAddress, length: length)
        guard let string = String(data: data, encoding: encoding) else { return nil }
        self = string
    }
}

extension TXTRecord {
    /// Extracts the TXT record data from a `ResourceRecord`, copying its contents.
    /// Returns `nil` if the record was not of type TXT.
    init?(_ resourceRecord: ResourceRecord) {
        guard ResourceRecordGetType(resourceRecord) == ns_t_txt else { return nil }
        
        var contents = ""
        let buffer = resourceRecord.dataBuffer
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

//
//  Transmission.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import Foundation

public class TransmissionManager {
    public func transmit(data: NSData, responseHandler: NSData -> ()) {

    }
}

public struct Transmission {
    public let data: NSData
    
    init(data: NSData) {
        self.data = data
    }
}
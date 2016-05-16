//
//  PacketTunnelProvider.swift
//  BurrowTunnel-iOS
//
//  Created by Jaden Geller on 4/4/16.
//
//

import NetworkExtension
@testable import Shovel

public struct AppleSystemLog: OutputStreamType {
    private init() { }
    public static var stream = AppleSystemLog()
    public func write(string: String) { NSLog(string) }
}

@objc class VolatileCondition: NSObject {
    @objc var value: Bool
    
    private init(_ value: Bool) {
        self.value = value
    }
    
    @objc static let sharedInstance = VolatileCondition(false)
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let sessionController = SessionController(domain: "burrow.tech") // TODO: Should we read from config?
    
    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        
        print("OMG IT WORKS!!!", toStream: &AppleSystemLog.stream)
        
        while !VolatileCondition.sharedInstance.value {
            sleep(1)
            print("SPAM!!!", toStream: &AppleSystemLog.stream)
        }
        
        sessionController.beginSession { result in
            // TODO: Convert to NSError and pass along?
            // TODO: Recover? Silently fail?
            try result.unwrap()
            completionHandler(nil)
            self.runTunnel()
        }
        
    }
    
    func runTunnel() {
        while true {
            // Forward packets
            packetFlow.readPacketsWithCompletionHandler {
                for (packet, protocolIdentifier) in zip($0, $1) {
                    // TODO: Support other protocols, definitely IPv6!!
                    assert(protocolIdentifier.intValue == AF_INET, "Unkown protocol \(protocolIdentifier)")
                    
                    self.sessionController.forwardPacket(packet) { result in
                        // TODO: Recover? Silently fail?
                        try! result.unwrap()
                    }
                }
            }
            
            // TODO: Request packets
        }
    }
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        print("OK, STOPPING NOW.")
        
        // TODO: We have to deal with syncronization issues.
        //       Best solution: Runloop acquires lock, and checks `release` bool each loop.
        sessionController.endSesssion { result in
            // TODO: Recover? Silently fail?
            try! result.unwrap()
            completionHandler()
            self.runTunnel()
        }
    }
    
    override func sleepWithCompletionHandler(completionHandler: () -> Void) {
        print("Sleeping!") // TODO: Should we stop the tunnel? How often does this happen?
        completionHandler()
    }
    
    override func wake() {
        print("Waking!")
    }
}

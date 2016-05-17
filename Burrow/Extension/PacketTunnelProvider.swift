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

// TODO: This might not be necessarily if we figure out what file descriptor print
//       normally goes to and redirect it to AppleSystemLog.
// https://github.com/iCepa/iCepa/blob/5c6de63a9ca91edc8ae76c9d177325f353747271/Extension/TunnelInterface.swift#L28-L31
func logErrors<T>(block: () throws -> T) -> T {
    do {
        return try block()
    } catch let error {
        print("Unrecoverable error: \(error)", toStream: &AppleSystemLog.stream)
        fatalError()
    }
}

@objc class VolatileCondition: NSObject {
    @objc var value: Bool
    
    private init(_ value: Bool) {
        self.value = value
    }
    
    @objc static let sharedInstance = VolatileCondition(false)
}

class PacketTunnelProvider: NEPacketTunnelProvider, SessionControllerDelegate {
    
    let sessionController = SessionController(domain: "burrow.tech") // TODO: Should we read from config?
    
    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        
        
        while true && !VolatileCondition.sharedInstance.value {
            sleep(1)
            print("SPAM!!!", toStream: &AppleSystemLog.stream)
        }

        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1") // TODO: FIGURE OUT WHAT THIS DOES
        settings.IPv4Settings = {
            let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
            ipv4Settings.includedRoutes = [NEIPv4Route.defaultRoute()]
            return ipv4Settings
        }()
        // TODO: WTF IS THIS
        settings.DNSSettings = NEDNSSettings(servers: ["8.8.8.8"])
        // TODO: IPV6?
        
        setTunnelNetworkSettings(settings) { error in

            if let error = error {
                print("OH NOES!!! ERROR: \(error)", toStream: &AppleSystemLog.stream)
                fatalError()
            }
            
            self.sessionController.delegate = self
            self.sessionController.beginSession { result in
                // TODO: Convert to NSError and pass along?
                // TODO: Recover? Silently fail?
                logErrors{ try result.unwrap() }
                completionHandler(nil)
                print("SUCCESSFULLY STARTED SESH!!! :D", toStream: &AppleSystemLog.stream)
                
                self.runTunnel()
            }

        }
    }
    
    func runTunnel() {

        forwardPackets()
        // TODO: Request packets

    }
    
    func forwardPackets() {
        // Forward packets

        packetFlow.readPacketsWithCompletionHandler { packets, protocolIdentifiers in
            
            // TODO: Refactor
            for (packet, protocolIdentifier) in zip(packets, protocolIdentifiers) {
                print("WILL FORWARD PACKET: \(packet)", toStream: &AppleSystemLog.stream)
                
                // TODO: Support other protocols, definitely IPv6!!
                assert(protocolIdentifier.intValue == AF_INET, "Unkown protocol \(protocolIdentifier)")
            }
            self.sessionController.forward(packets: packets) { result in
                // TODO: Recover? Silently fail?
                try! result.unwrap()
            }

            print("TRYING AGAIN!!!", toStream: &AppleSystemLog.stream)

            self.forwardPackets()
        }
    }
    
    func handleReceived(packets packets: Result<[NSData]>) {
        // TODO: Handle errors
        let packets = try! packets.unwrap()
        // TODO: Handle protocol.
        print("DID RECIEVE PACKETs: \(packets)", toStream: &AppleSystemLog.stream)
        packetFlow.writePackets(packets, withProtocols: Array(Repeat(count: packets.count, repeatedValue: NSNumber(int: AF_INET))))
    }
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        print("OK, STOPPING NOW.")
        
        // TODO: We have to deal with syncronization issues.
        //       Best solution: Runloop acquires lock, and checks `release` bool each loop.
        sessionController.endSesssion { result in
            // TODO: Recover? Silently fail?
            logErrors{ try result.unwrap() }
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

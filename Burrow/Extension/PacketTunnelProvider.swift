//
//  PacketTunnelProvider.swift
//  BurrowTunnel-iOS
//
//  Created by Jaden Geller on 4/4/16.
//
//

import NetworkExtension
@testable import Shovel

// TODO: This might not be necessarily if we figure out what file descriptor print
//       normally goes to and redirect it to AppleSystemLog.
// https://github.com/iCepa/iCepa/blob/5c6de63a9ca91edc8ae76c9d177325f353747271/Extension/TunnelInterface.swift#L28-L31
func logErrors<T>(block: () throws -> T) -> T {
    do {
        return try block()
    } catch let error {
        log("Unrecoverable error: \(error)")
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
        log("Starting tunnel...")

        
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
            log("Set tunnel network settings")

            if let error = error {
                print("OH NOES!!! ERROR: \(error)", toStream: &AppleSystemLog.stream)
                fatalError()
            }
            
            self.sessionController.delegate = self
            self.sessionController.beginSession { result in
                // TODO: Identifier should be printed. Should this code be in the session controller?
                log("Began tunneling session with identifier")

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
            dispatch_async(dispatch_get_main_queue()) {
                log("Read \(packets.count) packets from device.")
                log("Read packets: \(packets)", requiresVerbose: true)
            }
            
            // TODO: Handle other types of packets.
            protocolIdentifiers.forEach {
                assert($0.intValue == AF_INET, "Unkown protocol \($0)")
            }
            
            self.sessionController.forward(packets: packets) { result in
                // TODO: Recover? Silently fail?
                try! result.unwrap()
            }
            
            // TODO: We probably shouldn't instantly ask for more...
            self.forwardPackets()
            
            sleep(1)
        }
    }
    
    func handleReceived(packets packets: Result<[NSData]>) {
        // TODO: Handle errors
        let packets = try! packets.unwrap()
        
        // TODO: MAKE THIS CLEANER
        dispatch_async(dispatch_get_main_queue()) {
            log("Received \(packets.count) packets from server.")
            log("Received packets: \(packets)", requiresVerbose: true)
        }

        // TODO: What is this return value?
        let value = packetFlow.writePackets(packets, withProtocols: Array(Repeat(count: packets.count, repeatedValue: NSNumber(int: AF_INET))))

        // TODO: Handle protocol.
        log("Writing packets... returned \(value)", requiresVerbose: true)
    }
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        log("Stopping the tunnel with reason: \(reason)")
        
        // TODO: We have to deal with syncronization issues.
        //       Best solution: Runloop acquires lock, and checks `release` bool each loop.
        sessionController.endSesssion { result in
            // TODO: Recover? Silently fail?
            logErrors{ try result.unwrap() }
            log("Successfully tore down session")
            completionHandler()
        }
    }
    
    override func sleepWithCompletionHandler(completionHandler: () -> Void) {
        // TODO: Should we stop the tunnel? How often does this happen?
        log("Sleeping tunnel")
        completionHandler()
    }
    
    override func wake() {
        log("Waking tunnel")
    }
}

//
//  PacketTunnelProvider.swift
//  BurrowTunnel-iOS
//
//  Created by Jaden Geller on 4/4/16.
//
//

import NetworkExtension
@testable import Shovel

import Logger
extension Logger { public static let packetTunnelProviderCategory = "PacketTunnelProvider" }
private let log = Logger.category(Logger.packetTunnelProviderCategory)

extension Logger {
    func caught<T>(@noescape block: () throws -> T) -> T {
        do {
            return try block()
        } catch let error {
            log.error("Unrecoverable error: \(error)")
            fatalError()
        }
    }
}

@objc class VolatileCondition: NSObject {
    @objc var value: Bool
    
    private init(_ value: Bool) {
        self.value = value
    }
    
    @objc static let sharedInstance = VolatileCondition(false)
}

let waitForDebugConnection = false

class PacketTunnelProvider: NEPacketTunnelProvider, SessionControllerDelegate {
    
    override init() {
        Logger.enable(minimumSeverity: .verbose)
        super.init()
    }
    
    let sessionController = SessionController(domain: "burrow.tech") // TODO: Should we read from config?
    
    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        while waitForDebugConnection && !VolatileCondition.sharedInstance.value {
            sleep(1)
            log.debug("Waiting for debug connection...")
        }
        log.info("Starting tunnel...")
        
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
            log.info("Set tunnel network settings")

            if let error = error {
                log.error("Unable to set tunnel network settings: \(error)")
                fatalError()
            }
            
            self.sessionController.delegate = self
            log.caught { try self.sessionController.beginSession().then { result in
                // TODO: Convert to NSError and pass along?
                // TODO: Recover? Silently fail?
                log.caught{ try result.unwrap() }

                // TODO: Identifier should be printed. Should this code be in the session controller?
                log.info("Began tunneling session with identifier")

                completionHandler(nil)
                self.runTunnel()
            } }

        }
    }
    
    func runTunnel() {

        forwardPackets()
        // TODO: Request packets

    }
    
    // TODO: What about the run loop?
    func forwardPackets() {
        // Forward packets

        log.debug("Attempting to read packets...")
        packetFlow.readPacketsWithCompletionHandler { packets, protocolIdentifiers in
            log.debug("Read \(packets.count) packets from device")
            log.verbose("Read \(packets)")
            
            // TODO: Handle other types of packets.
            protocolIdentifiers.forEach {
                assert($0.intValue == AF_INET, "Unkown protocol \($0)")
            }
            
            log.caught { try self.sessionController.forward(packets: packets).then { result in
                // TODO: Recover? Silently fail?
                log.caught{ try result.unwrap() }
            } }
            
            // TODO: We probably shouldn't instantly ask for more...
            self.forwardPackets()
            
            sleep(1)
        }
    }
    
    func handleReceived(packets packets: Result<[NSData]>) {
        // TODO: Handle errors
        let packets = log.caught{ try packets.unwrap() }
        
        log.debug("Received \(packets.count) packets from server.")
        log.verbose("Received: \(packets)")

        // TODO: What is this return value?
        let value = packetFlow.writePackets(packets, withProtocols: Array(Repeat(count: packets.count, repeatedValue: NSNumber(int: AF_INET))))

        // TODO: Handle protocol.
        log.debug("Writing packets... returned \(value)")
    }
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        log.info("Stopping the tunnel with reason: \(reason)")
        
        // TODO: We have to deal with syncronization issues.
        //       Best solution: Runloop acquires lock, and checks `release` bool each loop.
        log.caught { try sessionController.endSesssion().then { result in
            // TODO: Recover? Silently fail?
            log.caught{ try result.unwrap() }
            log.info("Successfully tore down session")
            completionHandler()
        } }
    }
    
    override func sleepWithCompletionHandler(completionHandler: () -> Void) {
        // TODO: Should we stop the tunnel? How often does this happen?
        log.info("Sleeping tunnel")
        completionHandler()
    }
    
    override func wake() {
        log.info("Waking tunnel")
    }
}

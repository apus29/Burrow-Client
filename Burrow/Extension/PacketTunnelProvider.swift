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

// Once this many or more than this many packets are in transit, will wait
// to read more from the OS.
let maximumNumberOfSimultaneousForwards = 50

class PacketTunnelProvider: NEPacketTunnelProvider, SessionControllerDelegate {
    
    override init() {
        Logger.enable(minimumSeverity: .info)
        super.init()
    }
    
    let sessionController = SessionController(domain: "burrow.tech")
    
    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        log.info("Starting tunnel...")
        
        // Confingure the tunnel
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.IPv4Settings = {
            let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
            ipv4Settings.includedRoutes = [NEIPv4Route.defaultRoute()]
            return ipv4Settings
        }()
        settings.DNSSettings = NEDNSSettings(servers: ["8.8.8.8"])
        
        setTunnelNetworkSettings(settings) { error in
            log.info("Set tunnel network settings")

            if let error = error {
                log.error("Unable to set tunnel network settings: \(error)")
                fatalError()
            }
            
            self.sessionController.delegate = self
            log.caught { try self.sessionController.beginSession().then { result in
                log.caught{ try result.unwrap() }
                log.info("Began tunneling session with identifier")

                // Let the OS know that the VPN has successfully connected.
                completionHandler(nil)
                
                // Forward packets with each run loop.
                let observer = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.BeforeWaiting.rawValue, true, 0) { [weak self] _ in
                    self?.forwardPackets()
                }
                CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopDefaultMode)
            } }

        }
    }
    
    var currentNumberOfSimultaneousForwards = 0
    func forwardPackets() {
        // Forward packets

        log.debug("Attempting to read packets for forwarding...")
        guard currentNumberOfSimultaneousForwards < maximumNumberOfSimultaneousForwards else {
            log.warning("Delaying packet forwarding: Too many packets already in transit.")
            return
        }
        packetFlow.readPacketsWithCompletionHandler { packets, protocolIdentifiers in
            guard !packets.isEmpty else { return }
            
            self.currentNumberOfSimultaneousForwards += packets.count
            
            log.debug("Read \(packets.count) packets from device")
            log.verbose("Read \(packets)")
            
            log.caught { try self.sessionController.forward(packets: packets).then { result in
                log.caught{
                    try result.unwrap()
                    self.currentNumberOfSimultaneousForwards -= packets.count
                }
            } }
        }
    }
    
    func handleReceived(packets packets: Result<[NSData]>) {
        let packets = log.caught{ try packets.unwrap() }
        
        log.debug("Received \(packets.count) packets from server.")
        log.verbose("Received: \(packets)")

        packetFlow.writePackets(packets, withProtocols: Array(Repeat(count: packets.count, repeatedValue: NSNumber(int: AF_INET))))
    }
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        log.info("Stopping the tunnel with reason: \(reason)")
        
        log.caught { try sessionController.endSesssion().then { result in
            log.caught{ try result.unwrap() }
            log.info("Successfully tore down session")
            completionHandler()
        } }
    }
    
    override func sleepWithCompletionHandler(completionHandler: () -> Void) {
        log.info("Sleeping tunnel")
        completionHandler()
    }
    
    override func wake() {
        log.info("Waking tunnel")
    }
}

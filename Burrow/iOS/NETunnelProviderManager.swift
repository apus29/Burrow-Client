//
//  NETunnelProviderManager.swift
//  Burrow
//
//  Created by Jaden Geller on 5/9/16.
//
//

import NetworkExtension
import Shovel // TODO: Refactor Result into separate module?
import Logger

// TODO: Share between iOS and OS X.
extension NETunnelProviderManager {
    class func sharedBurrowTunnelProviderManager(completionHandler: Result<NETunnelProviderManager> -> ()) {
        self.loadAllFromPreferencesWithCompletionHandler { managers, error in
            if let error = error {
                // Propagate the error
                completionHandler(.Failure(error))
            }
            else if let manager = managers?.first {
                log.precondition(managers!.count == 1)
                
                // Return the existing manager
                completionHandler(.Success(manager))
            } else {
                // Create a new manager
                let manager = NETunnelProviderManager()
                manager.protocolConfiguration = {
                    let configuration = NETunnelProviderProtocol()
                    configuration.providerConfiguration = [:]
                    configuration.providerBundleIdentifier = "tech.burrow.client.ios.extension"
                    configuration.serverAddress = "burrow.tech"
                    return configuration
                }()
                manager.localizedDescription = "DNS Tunnel"
                
                // Save to preferences
                manager.saveToPreferencesWithCompletionHandler { error in
                    if let error = error {
                        // Propoagate error
                        completionHandler(.Failure(error))
                    }
                    else {
                        // Return the new manager
                        completionHandler(.Success(manager))
                    }
                }
            }
        }
    }
}

//
//  ViewController.swift
//  Burrow-Mac
//
//  Created by Jaden Geller on 4/4/16.
//
//

import Cocoa
import NetworkExtension

class ViewController: NSViewController {
    var tunnelProviderManager: NETunnelProviderManager!
    @IBOutlet weak var toggleButton: NSButton!

    @IBAction func togglePress(sender: NSButton) {
        assert([0, 1].contains(sender.state))
        let enabled = sender.state == 1
        
        switch enabled {
        case true:
            print("User enabled tunnel.")
            
            // TODO: Listen for notifications
            do {
                assert(tunnelProviderManager.enabled)
                tunnelProviderManager.saveToPreferencesWithCompletionHandler {
                    error in
                    try! self.tunnelProviderManager.connection.startVPNTunnel()
                }
            } catch let error as NSError {
                print("ERROR!!!", error, NEVPNError(rawValue: error.code)! == .ConfigurationInvalid)
            }

        case false:
            
            print("User disabled tunnel.")

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NETunnelProviderManager.sharedBurrowTunnelProviderManager { result in
            do {
                let manager = try result.unwrap()
                self.tunnelProviderManager = manager
                print("Successfull retrived tunnel provider manager.")
                
                manager.loadFromPreferencesWithCompletionHandler { error in
                    if let error = error {
                        print("Unable to load tunnel provider manager.", error)
                    } else {
                        print("Successfull loaded tunnel provider manager.")
                        
                        if !manager.enabled {
                            manager.enabled = true
                            manager.saveToPreferencesWithCompletionHandler { error in
                                if let error = error {
                                    print("Unable to save tunnel provider manager.", error)
                                } else {
                                    self.toggleButton.enabled = true
                                }
                            }
                        } else {
                            self.toggleButton.enabled = true
                        }
                    }
                }
            } catch let error {
                // TODO: This might fail the first time the app is launched.
                print("Unable to load tunnel provider manager.", error)
            }
        }

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}


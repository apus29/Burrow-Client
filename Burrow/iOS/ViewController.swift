//
//  ViewController.swift
//  Burrow-iOS
//
//  Created by Jaden Geller on 4/4/16.
//
//

import UIKit
import NetworkExtension
import Logger

class ViewController: UIViewController {
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    var tunnelProviderManager: NETunnelProviderManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
            
        NETunnelProviderManager.sharedBurrowTunnelProviderManager { result in
            do {
                let manager = try result.unwrap()
                self.tunnelProviderManager = manager
                print("Successfully retrived tunnel provider manager.")
                
                // TODO: Is this necessary?
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
                                    self.toggleSwitch.enabled = true
                                }
                            }
                        } else {
                            self.toggleSwitch.enabled = true
                        }
                    }
                }
            } catch let error {
                // TODO: This might fail the first time the app is launched.
                print("Unable to load tunnel provider manager.", error)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(statusChanged), name: NEVPNStatusDidChangeNotification, object: nil)
    }
    
    func statusChanged() {
        if let tunnelProviderManager = tunnelProviderManager {
            toggleSwitch.on = [.Connecting, .Connected].contains(tunnelProviderManager.connection.status)
            tunnelVisuallyEnabled(toggleSwitch.on)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tunnelVisuallyEnabled(enabled: Bool) {
        let lingerDuration = 0.1
        let animationDuration = NSTimeInterval(UINavigationControllerHideShowBarDuration) * 2 + lingerDuration
        let waitDuration = NSTimeInterval(UINavigationControllerHideShowBarDuration) + lingerDuration

        if enabled {
            UIView.animateWithDuration(animationDuration) {
                self.view.backgroundColor = .darkGrayColor()
            }
            
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(waitDuration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.navigationBar.barStyle = .Black
                self.title = "Burrow (Enabled)"
            }
        } else {
            UIView.animateWithDuration(animationDuration) {
                self.view.backgroundColor = .whiteColor()
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(waitDuration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.navigationBar.barStyle = .Default
                self.title = "Burrow (Disabled)"
            }
        }
    }
    
    @IBAction func tunnelToggle(sender: UISwitch) {
        tunnelVisuallyEnabled(sender.on)
        if sender.on {
            print("User enabled tunnel.")
            
            // TODO: Listen for notifications
            do {
                log.precondition(tunnelProviderManager.enabled)
                log.precondition(tunnelProviderManager.routingMethod == .DestinationIP)
                log.precondition(tunnelProviderManager.copyAppRules() == nil)
                tunnelProviderManager.saveToPreferencesWithCompletionHandler {
                    error in
                    try! self.tunnelProviderManager.connection.startVPNTunnel()
                }
            }
            
        } else {
            print("User disabled tunnel.")
            self.tunnelProviderManager.connection.stopVPNTunnel()
            
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            
        }
    }
}


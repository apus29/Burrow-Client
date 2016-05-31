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
            toggleSwitch.enabled = tunnelProviderManager.connection.status.rawValue >= NEVPNStatus.Connecting.rawValue
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tunnelToggle(sender: UISwitch) {
        // THIS CODE IS LITERALLY BARF
        // DON'T WORRY, I'LL REFACTOR WHEN WE GET A BETTER IDEA OF WHAT WE'D LIKE
        
        let lingerDuration = 0.1
        let animationDuration = NSTimeInterval(UINavigationControllerHideShowBarDuration) * 2 + lingerDuration
        let waitDuration = NSTimeInterval(UINavigationControllerHideShowBarDuration) + lingerDuration
        
        if sender.on {
            UIView.animateWithDuration(animationDuration) {
                self.view.backgroundColor = .darkGrayColor()
            }

            self.navigationController?.setNavigationBarHidden(true, animated: true)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(waitDuration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.navigationBar.barStyle = .Black
                self.title = "Burrow (Enabled)"
            }
            print("User enabled tunnel.")
            
            // TODO: Listen for notifications
            do {
                assert(tunnelProviderManager.enabled)
                assert(tunnelProviderManager.routingMethod == .DestinationIP)
                assert(tunnelProviderManager.copyAppRules() == nil)
                tunnelProviderManager.saveToPreferencesWithCompletionHandler {
                    error in
                    try! self.tunnelProviderManager.connection.startVPNTunnel()
                }
            }
            
        } else {
            UIView.animateWithDuration(animationDuration) {
                self.view.backgroundColor = .whiteColor()
            }
            print("User disabled tunnel.")
            
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(waitDuration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.navigationBar.barStyle = .Default
                self.title = "Burrow (Disabled)"
            }
        }
    }
}


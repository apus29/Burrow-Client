//
//  ViewController.swift
//  Burrow-iOS
//
//  Created by Jaden Geller on 4/4/16.
//
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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


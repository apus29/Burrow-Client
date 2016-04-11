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
        if sender.on {
            print("User enabled tunnel.")
        } else {
            print("User disabled tunnel.")
        }
    }
}


//
//  ViewController.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 24/11/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var dataTextField: UITextField!
    @IBOutlet weak var advertiseButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var sendDataButton: UIButton!
    @IBOutlet weak var connectionsNumberLabel: UILabel!

    let manager = MPCManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        advertiseButton.addTarget(self, action: #selector(advertisePressed), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(connectPressed), for: .touchUpInside)
    }

    func advertisePressed(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            advertiseButton.setTitle("Stop advertising", for: .normal)
            connectButton.isEnabled = false
            manager.startAdvertising()
        } else {
            advertiseButton.setTitle("Start advertising", for: .normal)
            connectButton.isEnabled = true
            manager.stopAdvertising()
        }
    }

    func connectPressed(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            connectButton.setTitle("Disconnect from session", for: .normal)
            advertiseButton.isEnabled = false
        } else {
            connectButton.setTitle("Connect to session", for: .normal)
            advertiseButton.isEnabled = true
        }
    }
}

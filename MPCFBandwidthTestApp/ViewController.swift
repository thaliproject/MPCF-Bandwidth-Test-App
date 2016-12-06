//
//  ViewController.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 24/11/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MPCManagerDelegate {

    @IBOutlet weak var dataTextField: UITextField!
    @IBOutlet weak var advertiseButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var openSteamButton: UIButton!
    @IBOutlet weak var sendDataButton: UIButton!
    @IBOutlet weak var connectionsNumberLabel: UILabel!

    var manager: MPCManager?
    var browser: Browser?

    override func viewDidLoad() {
        super.viewDidLoad()
        advertiseButton.addTarget(self, action: #selector(advertisePressed), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(connectPressed), for: .touchUpInside)
        openSteamButton.addTarget(self, action: #selector(openStreamPressed), for: .touchUpInside)
        sendDataButton.addTarget(self, action: #selector(sendDataPressed), for: .touchUpInside)
    }

    func advertisePressed(sender: UIButton) {
        if manager == nil {
            manager = MPCManager(master: true)
            manager?.delegate = self
        }
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            advertiseButton.setTitle("Stop advertising", for: .normal)
            connectButton.isEnabled = false
            manager!.start()
        } else {
            advertiseButton.setTitle("Start advertising", for: .normal)
            connectButton.isEnabled = true
            manager!.stop()
        }
    }

    func connectPressed(sender: UIButton) {
        if manager == nil {
            manager = MPCManager(master: false)
            manager?.delegate = self
        }
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            connectButton.setTitle("Disconnect from session", for: .normal)
            advertiseButton.isEnabled = false
            manager?.start()
        } else {
            connectButton.setTitle("Connect to session", for: .normal)
            advertiseButton.isEnabled = true
            manager?.stop()
        }
    }

    func openStreamPressed(sender: UIButton) {
//        if manager!.outputStream == nil {
//            sender.isSelected = !sender.isSelected
////            manager.openStream()
//            openSteamButton.setTitle("Stream opened", for: .normal)
//        }
    }

    func sendDataPressed(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            manager!.sendData()
        } else {
        }
    }

    func peerCounterChanged() {
         DispatchQueue.main.async {
            self.connectionsNumberLabel.text = "\(self.manager!.numberOfConnections)"
        }
    }

    // MARK: - MCBrowserViewControllerDelegate

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
}

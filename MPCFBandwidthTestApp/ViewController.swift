//
//  ViewController.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 24/11/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate {

    @IBOutlet weak var dataTextField: UITextField!
    @IBOutlet weak var advertiseButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var openSteamButton: UIButton!
    @IBOutlet weak var sendDataButton: UIButton!
    @IBOutlet weak var connectionsNumberLabel: UILabel!

    let manager = MPCManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        advertiseButton.addTarget(self, action: #selector(advertisePressed), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(connectPressed), for: .touchUpInside)
        openSteamButton.addTarget(self, action: #selector(openStreamPressed), for: .touchUpInside)
        sendDataButton.addTarget(self, action: #selector(sendDataPressed), for: .touchUpInside)
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
            showConnectView()
        } else {
            connectButton.setTitle("Connect to session", for: .normal)
            advertiseButton.isEnabled = true
        }
    }

    func openStreamPressed(sender: UIButton) {
        if manager.outputStream == nil {
            sender.isSelected = !sender.isSelected
            manager.openStream()
            openSteamButton.setTitle("Stream opened", for: .normal)
        }
    }

    func sendDataPressed(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            manager.sendData()
        } else {
        }
    }

    func showConnectView() {
        let browser = MCBrowserViewController(serviceType: manager.serviceType, session: manager.session)
        browser.delegate = self
        present(browser, animated: true)
    }

    // MARK: - MCBrowserViewControllerDelegate

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
}

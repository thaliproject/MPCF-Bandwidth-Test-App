//
//  MPCManager.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 24/11/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import UIKit
import MultipeerConnectivity

public class MPCManager: NSObject, MCSessionDelegate {

    var session: MCSession!
    var peerID: MCPeerID!
    var advertiserAssistant: MCAdvertiserAssistant!

    // Singleton setup
    static let shared = MPCManager()
    private override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        advertiserAssistant = MCAdvertiserAssistant(serviceType: "MPCF-Bandwidth-Test-App", discoveryInfo: nil, session: session)
    }

    // MARK: - Session controls

    func startAdvertising() {
        self.advertiserAssistant.start()
    }

    func stopAdvertising() {
        self.advertiserAssistant.stop()
    }

    func joinSession() {

    }

    // MARK: - MCSessionDelegate

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
    }
}

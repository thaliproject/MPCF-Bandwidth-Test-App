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

    let serviceType: String = "MPCF-Speed-Test"
    var session: MCSession!
    var peerID: MCPeerID!
    var advertiserAssistant: MCAdvertiserAssistant!
    var outputStream: OutputStream?
    var inputStream: InputStream?

    // Singleton setup
    static let shared = MPCManager()
    private override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        advertiserAssistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
    }

    // MARK: - Session controls

    func startAdvertising() {
        self.advertiserAssistant.start()
    }

    func stopAdvertising() {
        self.advertiserAssistant.stop()
    }

    func openStream() {
        do {
            let stream = try session.startStream(withName: "Main", toPeer: session.connectedPeers[0])
            self.outputStream = stream
        } catch {
            print("Couldn't open stream")
        }
    }

    func sendData() {
        let data = Data.generateDataBy(numberOfBytes: 1000)
        let result = outputStream?.write(data.withUnsafeBytes {UnsafePointer<UInt8>($0)}, maxLength: data.count)
        print(result ?? 0)
    }

    // MARK: - MCSessionDelegate

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        self.inputStream = stream
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
    }
}

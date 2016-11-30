//
//  MPCManager.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 24/11/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import UIKit
import MultipeerConnectivity

public class MPCManager: NSObject, MCSessionDelegate, StreamDelegate {

    internal fileprivate(set) var opened = false
    let serviceType: String = "MPCF-Speed-Test"
    var session: MCSession!
    var peerID: MCPeerID!
    var advertiserAssistant: MCAdvertiserAssistant!
    var outputStream: OutputStream?
    var inputStream: InputStream?
    var delegate: MPCManagerDelegate?
    let maxReadBufferLength = 1024 * 1024
    var startTime: DispatchTime!
    var endTime: DispatchTime!

    var numberOfConnections: Int = 0 {
        didSet {
            delegate?.peerCounterChanged()
        }
    }

    // Singleton setup
    static let shared = MPCManager()
    private override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
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
            self.outputStream?.schedule(in: RunLoop.current,
                            forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStream?.open()
            RunLoop.current.run(until: Date.distantFuture)
        } catch {
            print("Couldn't open stream")
        }
    }

    func sendData() {
        let data = Data.generateDataBy(numberOfBytes: 1000000)
        dump(data)
        let _ = data.withUnsafeBytes{ print(self.outputStream?.write($0, maxLength: data.count) ?? 0) }
    }

    func readData() {
        if let inputStream = self.inputStream {
            var buffer = [UInt8](repeating: 0, count: maxReadBufferLength)

            let bytesRead = inputStream.read(&buffer, maxLength: maxReadBufferLength)
            if bytesRead >= 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                endTime = DispatchTime.now()
                let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000

                print("Time to receive \(data.count) bytes: \(timeInterval) microseconds")
                print("Did read data from stream")
            } else {
                closeStreams()
            }
        }
    }

    func closeStreams() {
        opened = false
        inputStream?.close()
        outputStream?.close()
    }

    // MARK: - MCSessionDelegate
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if aStream == self.inputStream {
            switch eventCode {
            case Stream.Event.openCompleted:
                print("Open Completed")
            case Stream.Event.hasBytesAvailable:
                startTime = DispatchTime.now()
                readData()
            case Stream.Event.hasSpaceAvailable:
                print("Close")
//                closeStreams()
            case Stream.Event.errorOccurred:
                print("Close")
//                closeStreams()
            case Stream.Event.endEncountered:
                print("Close")
//                closeStreams()
            default:
                break
            }
        }
    }

    // MARK: - MCSessionDelegate

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            print("connected")
            numberOfConnections += 1
        } else if state == .notConnected {
            print("disconnected")
            numberOfConnections -= 1
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        self.inputStream = stream
        stream.schedule(in: RunLoop.current,
                         forMode: RunLoopMode.defaultRunLoopMode)
        stream.open()
        stream.delegate = self
        RunLoop.current.run(until: Date.distantFuture)
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
    }
}

protocol MPCManagerDelegate {
    func peerCounterChanged()
}

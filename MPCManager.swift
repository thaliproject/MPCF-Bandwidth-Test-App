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
    var session: MCSession! {
        didSet {
            session.delegate = self
        }
    }
    var peerID: MCPeerID!
    var advertiserAssistant: MCAdvertiserAssistant!
    var advertiser: Advertiser!
    var outputStream: OutputStream?
    var returnStream: OutputStream?
    var inputStream: InputStream?
    var returnInputStream: InputStream?
    var delegate: MPCManagerDelegate?
    let maxReadBufferLength = 1024 * 1024
    var totalData: Int = 0
    let bytesToSend: Int = 1024*1024
    var startDate: Date!

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
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = Advertiser(peer: peerID, serviceType: serviceType, receivedInvitation: {
            [weak self] session in
            guard let strongSelf = self else { return }

            strongSelf.session = session.session
            }, sessionNotConnected: {})
        advertiserAssistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
    }

    // MARK: - Session controls

    func startAdvertising() {
        self.advertiser.startAdvertising({_ in})
    }

    func stopAdvertising() {
        self.advertiser.stopAdvertising()
    }

    func openStream() {
        do {
            let stream = try session.startStream(withName: "Outgoing", toPeer: session.connectedPeers[0])
            self.outputStream = stream
            self.outputStream?.schedule(in: RunLoop.current,
                            forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStream?.open()
            RunLoop.current.run(until: Date.distantFuture)
        } catch {
            print("Couldn't open stream")
        }
    }

    func openReturnStreamAndSendData() {
        do {
            let stream = try session.startStream(withName: "Return \(UIDevice.current.name)", toPeer: session.connectedPeers[0])
            self.returnStream = stream
            self.returnStream?.schedule(in: RunLoop.current,
                                        forMode: RunLoopMode.defaultRunLoopMode)
            self.returnStream?.open()
            sendReturnData()
        } catch {
            print("Couldn't open stream")
        }
    }

    func sendData() {
        startDate = Date()
        let data = Data.generateDataBy(numberOfBytes: bytesToSend)
        dump(data)

        _ = data.withUnsafeBytes{ print(self.outputStream?.write($0, maxLength: data.count) ?? 0.0 ) }
    }

    func sendReturnData() {
        let data = Data.generateDataBy(numberOfBytes: 1)
        dump(data)

        _ = data.withUnsafeBytes{ print(self.returnStream?.write($0, maxLength: data.count) ?? 0.0 ) }
    }

    func readData() {
        if let inputStream = self.inputStream {
            var buffer = [UInt8](repeating: 0, count: maxReadBufferLength)

            let bytesRead = inputStream.read(&buffer, maxLength: maxReadBufferLength)
            if bytesRead >= 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                totalData += data.count
                print(totalData)

                if totalData == bytesToSend {
                    print("Received all the data")
                    self.inputStream?.close()
                    openReturnStreamAndSendData()


                }
            } else {
                closeStreams()
            }
        }
    }

    func readReturnData() {
        if let returnInputStream = self.returnInputStream {
            var buffer = [UInt8](repeating: 0, count: maxReadBufferLength)

            let bytesRead = returnInputStream.read(&buffer, maxLength: maxReadBufferLength)
            if bytesRead >= 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                let endDate = Date().timeIntervalSince(startDate as Date)

                print("Recieved in return \(data.count) byte. Time to send \(bytesToSend) bytes and get response: \(endDate) seconds")
                let speed = 1/endDate
                print("Transfer with confirmation speed: \(speed) MB/s")
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
                print("Main input - openCompleted")
            case Stream.Event.hasBytesAvailable:
                print("Main input - hasBytesAvailable")
                readData()
            case Stream.Event.hasSpaceAvailable:
                print("Main input - hasSpaceAvailable")
//                closeStreams()
            case Stream.Event.errorOccurred:
                print("Main input - errorOccurred")
//                closeStreams()
            case Stream.Event.endEncountered:
                print("Main input - errorOccurred")
//                closeStreams()
            default:
                break
            }
        } else {
            switch eventCode {
            case Stream.Event.openCompleted:
                print("Return input - Open Completed")
            case Stream.Event.hasBytesAvailable:
                print("Return input - hasBytesAvailable")
                readReturnData()
            case Stream.Event.hasSpaceAvailable:
                print("Return input - hasSpaceAvailable")
//                closeStreams()
            case Stream.Event.errorOccurred:
                print("Return input - errorOccurred")
//                closeStreams()
            case Stream.Event.endEncountered:
                print("Return input - endEncountered")
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
//            if !self.session.connectedPeers.contains(peerID) {
                numberOfConnections += 1
//            }
        } else if state == .notConnected {
            print("disconnected")
//            if self.session.connectedPeers.contains(peerID) {
                numberOfConnections -= 1
//            }
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print(streamName)
        if streamName == "Outgoing" {
            self.inputStream = stream
        } else {
            self.returnInputStream = stream
        }
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

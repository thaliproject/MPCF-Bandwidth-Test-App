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

    let serviceType: String = "MPCF-out"
    let returnServiceType: String = "MPCF-return"

    var advertSession: MCSession! {
        didSet {
            advertSession.delegate = self
        }
    }

    var browseSession: MCSession! {
        didSet {
            browseSession.delegate = self
        }
    }

    var peerIDFirst: MCPeerID!
    var peerIDSecond: MCPeerID!
    var returnPeerID: MCPeerID!
    var browser: Browser!
    var advertiser: Advertiser!
    var nameMaster: String!
    var nameSlave: String!

    var outputStreamFromAdvertiser: OutputStream?
    var inputStreamToAdvertiser: InputStream?

    var outputStreamFromBrowser: OutputStream?
    var inputStreamToBrowser: InputStream?

    var delegate: MPCManagerDelegate?
    let maxReadBufferLength = 1024 * 1024
    let bytesToSend: Int = 1024 * 1024
    var startDate: Date!
    var master = false
    var returnSessionStarted = false
    var outStreamOpen = false
    var otherIDOne: MCPeerID!
    var otherIDTwo: MCPeerID!

    var numberOfConnections: Int = 0 {
        didSet {
            delegate?.peerCounterChanged()
        }
    }

    // Singleton setup
    init(master: Bool) {
        super.init()

        self.master = master

        nameMaster = master ? "m1" : "m2"
        nameSlave = master ? "s2" : "s1"

        peerIDFirst = MCPeerID(displayName: nameMaster)
        peerIDSecond = MCPeerID(displayName: nameSlave)

        let advService = master ? serviceType : returnServiceType
        let browserService = master ? returnServiceType : serviceType

        // Advertiser
        self.advertiser = Advertiser(peer: peerIDFirst, serviceType: advService, receivedInvitation: {
            [weak self] session in
            guard let strongSelf = self else { return }

            strongSelf.advertSession = session.session
            }, sessionNotConnected: {})

        // Browser
        self.browser = Browser(serviceType: browserService,
                          myPeerID: nameSlave,
                          foundPeer: handleFound,
                          lostPeer: handleLost)
    }

    func handleFound(_ peer: MCPeerID) {
        do {
            try browser!.inviteToConnect(peer, sessionConnected: {}, sessionNotConnected: {}, sessionCreated: { session in self.browseSession = session.session})
        } catch {
            print(MPCError.peerError)
        }
    }

    func handleLost(_ peer: MCPeerID) {
    }

    func start() {
        if master {
            startAdvertising()
        } else {
            startBrowsing()
        }
    }

    func stop() {
        if master {
            stopAdvertising()
        } else {
            stopBrowsing()
        }
    }

    // MARK: - Session controls

    func startAdvertising() {
        self.advertiser.startAdvertising({_ in})
    }

    func stopAdvertising() {
        self.advertiser.stopAdvertising()
    }

    func startBrowsing() {
        self.browser.startListening { _ in }
    }

    func stopBrowsing() {
        self.browser.stopListening()
    }

    func openStream(peer: MCPeerID) {
        do {
//            let streamName = nameMaster + ""
            let stream = try advertSession.startStream(withName: "\(nameMaster)", toPeer: peer)
            self.outputStreamFromAdvertiser = stream
            self.outputStreamFromAdvertiser?.schedule(in: RunLoop.current,
                            forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStreamFromAdvertiser?.open()
            RunLoop.current.run(until: Date.distantFuture)
        } catch {
            print("Couldn't open stream")
        }
    }

    func openReturnStreamAndSendData(peer: MCPeerID) {
        do {
            let name = master ? "s2" : "s1"
            let stream = try advertSession.startStream(withName: "\(name)", toPeer: peer)
            self.outputStreamFromBrowser = stream
            self.outputStreamFromBrowser?.schedule(in: RunLoop.current,
                                        forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStreamFromBrowser?.open()
        } catch {
            print("Couldn't open stream")
        }
    }

    func sendData() {
        startDate = Date()
        let data = Data.generateDataBy(numberOfBytes: bytesToSend)
        dump(data)

        _ = data.withUnsafeBytes{ print(self.outputStreamFromAdvertiser?.write($0, maxLength: data.count) ?? 0.0 ) }
    }

    func sendReturnData() {
        let data = Data.generateDataBy(numberOfBytes: 1)
        dump(data)

        _ = data.withUnsafeBytes{ print(self.outputStreamFromBrowser?.write($0, maxLength: data.count) ?? 0.0 ) }
    }

    func readData() {
        if let inputStream = self.inputStreamToBrowser {
//            var buffer = [UInt8](repeating: 0, count: maxReadBufferLength)
//
//            let bytesRead = inputStream.read(&buffer, maxLength: maxReadBufferLength)
//            if bytesRead >= 0 {
//                let data = Data(bytes: buffer, count: bytesRead)
//                totalData += data.count
//                print(totalData)
//
//                if totalData == bytesToSend {
//                    print("Received all the data")
//                    self.inputStreamToBrowser?.close()
////                    openReturnStreamAndSendData()
//                }
//            } else {
//                closeStreams()
//            }
        }
    }

    func readReturnData() {
        if let returnInputStream = self.inputStreamToAdvertiser {
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
        inputStreamToBrowser?.close()
        outputStreamFromAdvertiser?.close()
    }

    // MARK: - MCSessionDelegate
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if aStream == self.inputStreamToBrowser {
            switch eventCode {
            case Stream.Event.openCompleted:
                print("Main input - openCompleted")
            case Stream.Event.hasBytesAvailable:
                print("Main input - hasBytesAvailable")
                readData()
            case Stream.Event.hasSpaceAvailable:
                print("Main input - hasSpaceAvailable")
            case Stream.Event.errorOccurred:
                print("Main input - errorOccurred")
            case Stream.Event.endEncountered:
                print("Main input - errorOccurred")
            default:
                break
            }
        } else if aStream == self.inputStreamToAdvertiser {
            switch eventCode {
            case Stream.Event.openCompleted:
                print("Return input - Open Completed")
            case Stream.Event.hasBytesAvailable:
                print("Return input - hasBytesAvailable")
                readReturnData()
            case Stream.Event.hasSpaceAvailable:
                print("Return input - hasSpaceAvailable")
            case Stream.Event.errorOccurred:
                print("Return input - errorOccurred")
            case Stream.Event.endEncountered:
                print("Return input - endEncountered")
            default:
                break
            }
        }
    }

    // MARK: - MCSessionDelegate

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {

        if session == session {

        } else if session == browseSession {
            print("hi")
        }
        if state == .connected {
            print("connected")
            numberOfConnections += 1
            if master {
                if !outStreamOpen {
                    otherIDOne = peerID
//                    openStream(peer: peerID)
                    browser.startListening { _ in }
                } else {
                    otherIDTwo = peerID
                    browser.stopListening()
                }
            } else {
                if !returnSessionStarted {
                    returnSessionStarted = true
                    otherIDOne = peerID
                    self.browser.stopListening()
                    self.advertiser.startAdvertising({_ in})
                } else {
                    otherIDTwo = peerID
//                    openStream(peer: peerID)
                    self.advertiser.stopAdvertising()
                }
            }
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
        if streamName == "Outgoing \(peerID.displayName)" {
            self.inputStreamToBrowser = stream
        } else if streamName == "Return \(peerID.displayName)" {
            self.inputStreamToAdvertiser = stream
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

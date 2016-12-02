//
//  Advertiser.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 02/12/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import MultipeerConnectivity

final class Advertiser: NSObject {

    internal fileprivate(set) var advertising: Bool = false

    internal let peer: MCPeerID

    fileprivate let advertiser: MCNearbyServiceAdvertiser

    fileprivate let didDisconnectHandler: () -> Void

    fileprivate let didReceiveInvitationHandler: (_ session: Session) -> Void

    fileprivate var startAdvertisingErrorHandler: ((Error) -> Void)? = nil

    required init?(peer: MCPeerID,
                   serviceType: String,
                   receivedInvitation: @escaping (_ session: Session) -> Void,
                   sessionNotConnected: @escaping () -> Void) {

        let advertiser = MCNearbyServiceAdvertiser(peer: peer,
                                                   discoveryInfo: nil,
                                                   serviceType: serviceType)
        self.peer = peer
        self.advertiser = advertiser
        self.didReceiveInvitationHandler = receivedInvitation
        self.didDisconnectHandler = sessionNotConnected
        super.init()
    }

    func startAdvertising(_ startAdvertisingErrorHandler: @escaping (Error) -> Void) {
        if !advertising {
            self.startAdvertisingErrorHandler = startAdvertisingErrorHandler
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            advertising = true
        }
    }

    /**
     Stops advertising the `serviceType` provided in init method.

     This method sets `advertising` value to `false`.
     It does not change state if `Advertiser` is already not advertising.
     */
    func stopAdvertising() {
        if advertising {
            advertiser.delegate = nil
            advertiser.stopAdvertisingPeer()
            advertising = false
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Advertiser: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        let mcSession = MCSession(peer: advertiser.myPeerID)

        let session = Session(session: mcSession,
                              identifier: peerID,
                              connected: {},
                              notConnected: didDisconnectHandler)

        invitationHandler(true, mcSession)
        didReceiveInvitationHandler(session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        stopAdvertising()
        startAdvertisingErrorHandler?(error)
    }
}

class Session: NSObject {

    // MARK: - Internal state

    /**
     Indicates the current state of a given peer within a `Session`.
     */
    internal fileprivate(set) var sessionState: MCSessionState = .notConnected

    /**
     Handles changing `sessionState`.
     */
    internal var didChangeStateHandler: ((MCSessionState) -> Void)?

    /**
     Handles receiving new InputStream.
     */
    internal var didReceiveInputStreamHandler: ((InputStream, String) -> Void)?

    // MARK: - Private state

    /**
     Represents `MCSession` object which enables and manages communication among all peers.
     */
    let session: MCSession

    /**
     Represents a peer in a session.
     */
    fileprivate let identifier: MCPeerID

    /**
     Handles underlying *MCSessionStateConnected* state.
     */
    fileprivate let didConnectHandler: () -> Void

    /**
     Handles underlying *MCSessionStateNotConnected* state.
     */
    fileprivate let didNotConnectHandler: () -> Void

    // MARK: - Public methods

    /**
     Returns a new `Session` object.

     - parameters:
     - session:
     Represents underlying `MCSession` object.

     - identifier:
     Represents a peer in a session.

     - connected:
     Called when the nearby peer’s state changes to `MCSessionStateConnected`.

     It means the nearby peer accepted the invitation and is now connected to the session.

     - notConnected:
     Called when the nearby peer’s state changes to `MCSessionStateNotConnected`.

     It means the nearby peer declined the invitation, the connection could not be established,
     or a previously connected peer is no longer connected.

     - returns:
     An initialized `Session` object.
     */
    init(session: MCSession,
         identifier: MCPeerID,
         connected: @escaping () -> Void,
         notConnected: @escaping () -> Void) {
        self.session = session
        self.identifier = identifier
        self.didConnectHandler = connected
        self.didNotConnectHandler = notConnected
        super.init()
//        self.session.delegate = self
    }

    /**
     Starts new `OutputStream` which represents a byte stream to a nearby peer.

     - parameters:
     - name:
     A name for the stream.

     - throws:
     ConnectionFailed if a stream could not be established.

     - returns:
     `OutputStream` object upon success.
     */
    func startOutputStream(with name: String) throws -> OutputStream {
        do {
            return try session.startStream(withName: name, toPeer: identifier)
        } catch {
            throw MPCError.outputStreamFail
        }
    }

    /**
     Disconnects the local peer from the session.
     */
    func disconnect() {
        session.disconnect()
    }
}

// MARK: - MCSessionDelegate - Handling events for MCSession
extension Session: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        assert(identifier.displayName == peerID.displayName)

        self.didChangeStateHandler?(sessionState)

        switch sessionState {
        case .notConnected:
            self.didNotConnectHandler()
        case .connected:
            self.didConnectHandler()
        case .connecting:
            break
        }
    }

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        assert(identifier.displayName == peerID.displayName)
        didReceiveInputStreamHandler?(stream, streamName)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        assert(identifier.displayName == peerID.displayName)
    }

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        assert(identifier.displayName == peerID.displayName)
    }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL,
                 withError error: Error?) {
        assert(identifier.displayName == peerID.displayName)
    }
}

public enum MPCError: String, Error {
    case outputStreamFail = "Failed to created output stream"
    case peerError = "Peer not found"
}

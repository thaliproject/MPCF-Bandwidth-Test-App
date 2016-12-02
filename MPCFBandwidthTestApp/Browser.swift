//
//  Browser.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 02/12/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import MultipeerConnectivity

/**
 The `Browser` class manages underlying `MCNearbyServiceBrowser` object
 and handles `MCNearbyServiceBrowserDelegate` events
 */
final class Browser: NSObject {

    // MARK: - Internal state

    /**
     Bool flag indicates if `Browser` object is listening for advertisements.
     */
    internal fileprivate(set) var listening: Bool = false

    /**
     Timeout for inviting a remote peer to a MCSession.
     */
    internal let invitePeerTimeout: TimeInterval = 30.0

    // MARK: - Private state

    /**
     MCNearbyServiceBrowser object.
     */
    fileprivate let browser: MCNearbyServiceBrowser

    /**
     Represents peers who can be invited into MCSession.
     */
    fileprivate var availablePeers: [MCPeerID] = []

    var peerSessions: [MCPeerID:Session] = [:]

    /**
     Handle finding nearby peer.
     */
    fileprivate let didFindPeerHandler: (MCPeerID) -> Void

    /**
     Handle losing nearby peer.
     */
    fileprivate let didLosePeerHandler: (MCPeerID) -> Void

    /**
     Handle failing browsing.
     */
    fileprivate var startBrowsingErrorHandler: ((Error) -> Void)? = nil

    // MARK: - Initialization

    /**
     Returns a new `Browser` object or nil if it could not be created.

     - parameters:
     - serviceType:
     The type of service to browse.
     This should be a string in the format of Bonjour service type:
     1. *Must* be 1–15 characters long
     2. Can contain *only* ASCII letters, digits, and hyphens.
     3. *Must* contain at least one ASCII letter
     4. *Must* not begin or end with a hyphen
     5. Hyphens must not be adjacent to other hyphens

     For more details, see [RFC6335](https://tools.ietf.org/html/rfc6335#section-5.1).

     - foundPeer:
     Called when a nearby peer is found.

     - lostPeer:
     Called when a nearby peer is lost.

     - returns:
     An initialized `Browser` object, or nil if an object could not be created
     due to invalid `serviceType` format.
     */
    required init?(serviceType: String,
                   foundPeer: @escaping (MCPeerID) -> Void,
                   lostPeer: @escaping (MCPeerID) -> Void) {

        let mcPeerID = MCPeerID(displayName: UUID().uuidString)
        browser = MCNearbyServiceBrowser(peer: mcPeerID, serviceType: serviceType)
        didFindPeerHandler = foundPeer
        didLosePeerHandler = lostPeer
    }

    // MARK: - Internal methods
    /**
     Begins listening for `serviceType` provided in init method.

     This method sets `listening` value to `true`.
     It does not change state if `Browser` is already listening.

     - parameters:
     - startListeningErrorHandler:
     Called when a browser failed to start browsing for peers.
     */
    func startListening(_ startListeningErrorHandler: @escaping (Error) -> Void) {
        if !listening {
            startBrowsingErrorHandler = startListeningErrorHandler
            browser.delegate = self
            browser.startBrowsingForPeers()
            listening = true
        }
    }

    /**
     Stops listening for the `serviceType` provided in init method.

     This method sets `listening` value to `false`.
     It does not change state if `Browser` is already not listening.
     */
    func stopListening() {
        browser.delegate = nil
        browser.stopBrowsingForPeers()
        listening = false
    }

    /**
     Invites Peer into the session

     - parameters:
     - peer:
     `Peer` to invite.

     - sessionConnected:
     Called when the peer is connected to this session.

     - sessionNotConnected:
     Called when the nearby peer is not (or is no longer) in this session.

     - throws: IllegalPeerID

     - returns: Session object that manages MCSession between peers
     */
    func inviteToConnect(_ peer: MCPeerID,
                         sessionConnected: @escaping () -> Void,
                         sessionNotConnected: @escaping () -> Void,
                         sessionCreated: (Session) -> Void) throws -> Session {
        let mcSession = MCSession(peer: browser.myPeerID,
                                  securityIdentity: nil,
                                  encryptionPreference: .required)

        if !availablePeers.contains(peer) {
            throw MPCError.peerError
        }

        let session = Session(session: mcSession,
                              identifier: peer,
                              connected: sessionConnected,
                              notConnected: sessionNotConnected)
        sessionCreated(session)

        peerSessions[peer] = session

        browser.invitePeer(peer,
                           to: mcSession,
                           withContext: nil,
                           timeout: invitePeerTimeout)
        return session
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension Browser: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        do {
            availablePeers.append(peerID)
            didFindPeerHandler(peerID)
        } catch let error {
            print("cannot parse identifier \"\(peerID.displayName)\" because of error: \(error)")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        do {
            if availablePeers.contains(peerID) {
                availablePeers.remove(at: availablePeers.index(of: peerID)!)
            }
            didLosePeerHandler(peerID)
        } catch let error {
            print("cannot parse identifier \"\(peerID.displayName)\" because of error: \(error)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        stopListening()
        startBrowsingErrorHandler?(error)
    }
}


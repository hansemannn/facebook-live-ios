//
//  FBSDKLiveVideoService.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 09.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

public protocol FBSDKLiveStreamDelegate {
    func liveStream(didStartWithSession session: VCSimpleSession);
    func liveStream(didStopWithSession session: VCSimpleSession);
}

extension FBSDKLiveStreamDelegate {
    func liveStream(didAbortWithError error: Error) {}
    func liveStream(didChangeSessionState sessionState: VCSessionState) {}
    func liveStream(didAddCameraSource cameraSource: VCSimpleSession) {}
}

enum FBSDKLiveStreamPrivacy : StringLiteralType {
    
    case me = "SELF"
    
    case friends = "FRIENDS"

    case friendsOfFriends = "FRIENDS_OF_FRIENDS"
    
    case allFriends = "ALL_FRIENDS"
    
    case custom = "CUSTOM"

}

enum FBSDKLiveStreamStatus: StringLiteralType {
    
    case unpublished = "UNPUBLISHED"

    case liveNow = "LIVE_NOW"

    case scheduledUnpublished = "SCHEDULED_UNPUBLISHED"

    case scheduledLive = "SCHEDULED_LIVE"

    case scheduledCanceled = "SCHEDULED_CANCELED"
}

enum FBSDKLiveStreamType: StringLiteralType {
    
    case regular = "REGULAR"
    
    case ambient = "AMBIENT"
}

open class FBSDKLiveVideoService: NSObject {
    
    var delegate: FBSDKLiveStreamDelegate!
    
    var privacy: FBSDKLiveStreamPrivacy!
    
    var plannedStartTime: Date!
    
    var status: FBSDKLiveStreamStatus!
    
    var type: FBSDKLiveStreamType!
    
    var title: String!

    var id: String!

    private var session: VCSimpleSession!
    
    private var sessionURL: NSURL!
    
    required public init(delegate: FBSDKLiveStreamDelegate, size: CGSize) {
        
        super.init()
        
        self.delegate = delegate
        self.type = .regular
        self.privacy = .me
        
        // self.session = VCSimpleSession(videoSize: size, frameRate: 30, bitrate: 1000000, useInterfaceOrientation: false)
        // self.session.delegate = self
    }
    
    func start() {
        
        guard FBSDKAccessToken.current().hasGranted("publish_actions") else {
            return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "The \"publish_actions\" permission has not been granted"))
        }
        
        let graphRequest = FBSDKGraphRequest(graphPath: "/\(self.privacy)/live_videos", parameters: ["privacy": "self"], httpMethod: "POST")
        
        DispatchQueue.main.async {
            _ = graphRequest?.start { (_, result, error) in
                guard error == nil else {
                    return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "Error initializing the live video session: \(String(describing: error?.localizedDescription))"))
                }
                
                self.id = (result as? NSDictionary)?.value(forKey: "id") as? String
                self.session.startRtmpSession(withURL: self.sessionURL.absoluteString, andStreamKey: "/\(self.id)/")
                self.delegate.liveStream(didStartWithSession:self.session)
            }
        }
    }
    
    func stop() {
        guard FBSDKAccessToken.current().hasGranted("publish_actions") else {
            return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "The \"publish_actions\" permission has not been granted"))
        }

        let graphRequest = FBSDKGraphRequest(graphPath: "/\(self.privacy)/live_videos", parameters: ["end_live_video": true], httpMethod: "POST")
        
        DispatchQueue.main.async {
            _ = graphRequest?.start { (_, _, error) in
                guard error == nil else {
                    return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "Error stopping the live video session: \(String(describing: error?.localizedDescription))"))
                }
                self.session.endRtmpSession()
                self.delegate.liveStream(didStopWithSession:self.session)
            }
        }
    }
    
    internal class func errorFromDescription(description: String) -> Error {
        return NSError(domain: FBSDKErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : description])
    }
}

extension FBSDKLiveVideoService : VCSessionDelegate {
    
    public func connectionStatusChanged(_ sessionState: VCSessionState) {
        // self.delegate.liveStream!(didChangeSessionState: sessionState)
    }
    
    public func didAddCameraSource(_ session: VCSimpleSession!) {
        // self.delegate.liveStream!(didAddCameraSource: session)
    }
}

//
//  FBSDKLiveVideoService.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 09.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

// MARK: Delegates

public protocol FBSDKLiveStreamDelegate {
    func liveStream(didStartWithSession session: VCSimpleSession);
    func liveStream(didStopWithSession session: VCSimpleSession);
}

extension FBSDKLiveStreamDelegate {
    func liveStream(didAbortWithError error: Error) {}
    func liveStream(didChangeSessionState sessionState: VCSessionState) {}
    func liveStream(didAddCameraSource cameraSource: VCSimpleSession) {}
}

// MARK: Enumerations

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
    
    var preview: UIView!
    
    var audience: String!

    var url: URL!

    var id: String!
    
    var frameRate: Int?
    
    var bitRate: Int?
    
    var isStreaming: Bool!

    private var session: VCSimpleSession!
    
    required public init(delegate: FBSDKLiveStreamDelegate, frameSize: CGRect, videoSize: CGSize) {
        
        super.init()
        
        self.delegate = delegate
        self.type = .regular
        self.privacy = .me
        self.audience = "me"
        self.frameRate = 30
        self.bitRate = 1000000
        self.isStreaming = false
        
        self.session = VCSimpleSession(videoSize: videoSize, frameRate: Int32(self.frameRate!), bitrate: Int32(self.bitRate!), useInterfaceOrientation: false)
        self.session.previewView.frame = frameSize
        self.session.delegate = self
        
        self.preview = self.session.previewView
    }
    
    // MARK: Public API's
    
    func start() {
        guard FBSDKAccessToken.current().hasGranted("publish_actions") else {
            return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "The \"publish_actions\" permission has not been granted"))
        }
        
        let graphRequest = FBSDKGraphRequest(graphPath: "/\(self.audience!)/live_videos", parameters: ["privacy":  "{\"value\":\"\(self.privacy.rawValue)\"}"], httpMethod: "POST")
        
        DispatchQueue.main.async {
            _ = graphRequest?.start { (_, result, error) in
                guard error == nil, let dict = (result as? NSDictionary) else {
                    return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "Error initializing the live video session: \(String(describing: error?.localizedDescription))"))
                }
                
                self.url = URL(string:(dict.value(forKey: "stream_url") as? String)!)
                self.id = dict.value(forKey: "id") as? String
                
                guard let streamPath = self.url?.lastPathComponent, let query = self.url?.query else {
                    return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "The stream path is invalid"))
                }
                
                self.session.startRtmpSession(withURL: "rtmp://rtmp-api.facebook.com:80/rtmp/", andStreamKey: "\(streamPath)?\(query)")
                self.delegate.liveStream(didStartWithSession:self.session)
            }
        }
    }
    
    func stop() {
        guard FBSDKAccessToken.current().hasGranted("publish_actions") else {
            return self.delegate.liveStream(didAbortWithError: FBSDKLiveVideoService.errorFromDescription(description: "The \"publish_actions\" permission has not been granted"))
        }

        let graphRequest = FBSDKGraphRequest(graphPath: "/\(self.audience!)/live_videos", parameters: ["end_live_video":  true], httpMethod: "POST")
        
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
    
    // MARK: Utilities
    
    internal class func errorFromDescription(description: String) -> Error {
        return NSError(domain: FBSDKErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : description])
    }
}

extension FBSDKLiveVideoService : VCSessionDelegate {
    
    public func connectionStatusChanged(_ sessionState: VCSessionState) {
        if (sessionState == .started) {
            self.isStreaming = true
        } else if (sessionState == .ended || sessionState == .error) {
            self.isStreaming = false
        }
        
        self.delegate.liveStream(didChangeSessionState: sessionState)
    }
    
    public func didAddCameraSource(_ session: VCSimpleSession!) {
        self.delegate.liveStream(didAddCameraSource: session)
    }
}

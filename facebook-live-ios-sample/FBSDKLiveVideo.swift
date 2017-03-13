//
//  FBSDKLiveVideo.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 09.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

// MARK: FBSDKLiveVideoDelegate

public protocol FBSDKLiveVideoDelegate {
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didStartWith session: FBSDKLiveVideoSession);
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didStopWith session: FBSDKLiveVideoSession);
}

extension FBSDKLiveVideoDelegate {
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didAbortWith error: Error) {}
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didChange sessionState: VCSessionState) {}
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didAdd cameraSource: VCSimpleSession) {}
}

// MARK: Enumerations

enum FBSDKLiveVideoPrivacy : StringLiteralType {
    case me = "SELF"
    
    case friends = "FRIENDS"

    case friendsOfFriends = "FRIENDS_OF_FRIENDS"
    
    case allFriends = "ALL_FRIENDS"
    
    case custom = "CUSTOM"
}

enum FBSDKLiveVideoStatus: StringLiteralType {
    case unpublished = "UNPUBLISHED"

    case liveNow = "LIVE_NOW"

    case scheduledUnpublished = "SCHEDULED_UNPUBLISHED"

    case scheduledLive = "SCHEDULED_LIVE"

    case scheduledCanceled = "SCHEDULED_CANCELED"
}

enum FBSDKLiveVideoType: StringLiteralType {
    case regular = "REGULAR"
    
    case ambient = "AMBIENT"
}

struct FBSDKLiveVideoParameter {
    var key: String!

    var value: String!
}

public class FBSDKLiveVideoSession : VCSimpleSession {
    
}

open class FBSDKLiveVideo: NSObject {
    var delegate: FBSDKLiveVideoDelegate!
    
    // MARK: Live Video Parameters
    
    var privacy: FBSDKLiveVideoPrivacy! = .me {
        didSet {
            self.updateLiveStreamParameters(with: FBSDKLiveVideoParameter(key: "privacy", value: "{\"value\":\"\(privacy.rawValue)\"}"))
        }
    }
    
    var plannedStartTime: Date! {
        didSet {
            self.updateLiveStreamParameters(with: FBSDKLiveVideoParameter(key: "planned_start_time", value: String(plannedStartTime.timeIntervalSince1970 * 1000)))
        }
    }
    
    var status: FBSDKLiveVideoStatus! {
        didSet {
            self.updateLiveStreamParameters(with: FBSDKLiveVideoParameter(key: "status", value: status.rawValue))
        }
    }
    
    var type: FBSDKLiveVideoType! = .regular {
        didSet {
            self.updateLiveStreamParameters(with: FBSDKLiveVideoParameter(key: "stream_type", value: type.rawValue))
        }
    }
    
    var title: String! {
        didSet {
            self.updateLiveStreamParameters(with: FBSDKLiveVideoParameter(key: "title", value: title))
        }
    }
    
    // MARK: Utility API's

    var url: URL!

    var id: String!
    
    var audience: String = "me"
    
    var frameRate: Int = 30
    
    var bitRate: Int = 1000000
    
    var preview: UIView!

    var isStreaming: Bool = false

    // MARK: Internal API's

    private var session: FBSDKLiveVideoSession!
    
    private var parameters: [String : String] = [:]
    
    required public init(delegate: FBSDKLiveVideoDelegate, previewSize: CGRect, videoSize: CGSize) {
        super.init()
        
        self.delegate = delegate
        
        self.session = FBSDKLiveVideoSession(videoSize: videoSize, frameRate: Int32(self.frameRate), bitrate: Int32(self.bitRate), useInterfaceOrientation: false)
        self.session.previewView.frame = previewSize
        self.session.delegate = self
        
        self.preview = self.session.previewView
    }
    
    deinit {
        if self.session.rtmpSessionState != .ended {
            self.session.endRtmpSession()
        }

        self.delegate = nil
        self.session.delegate = nil
        self.preview = nil
    }
    
    // MARK: Public API's
    
    func start() {
        guard FBSDKAccessToken.current().hasGranted("publish_actions") else {
            return self.delegate.liveVideo(self, didAbortWith: FBSDKLiveVideo.errorFromDescription(description: "The \"publish_actions\" permission has not been granted"))
        }
        
        let graphRequest = FBSDKGraphRequest(graphPath: "/\(self.audience)/live_videos", parameters: self.parameters, httpMethod: "POST")
        
        DispatchQueue.main.async {
            _ = graphRequest?.start { (_, result, error) in
                guard error == nil, let dict = (result as? NSDictionary) else {
                    return self.delegate.liveVideo(self, didAbortWith: FBSDKLiveVideo.errorFromDescription(description: "Error initializing the live video session: \(String(describing: error?.localizedDescription))"))
                }
                
                self.url = URL(string:(dict.value(forKey: "stream_url") as? String)!)
                self.id = dict.value(forKey: "id") as? String
                
                guard let streamPath = self.url?.lastPathComponent, let query = self.url?.query else {
                    return self.delegate.liveVideo(self, didAbortWith: FBSDKLiveVideo.errorFromDescription(description: "The stream path is invalid"))
                }
                
                self.session.startRtmpSession(withURL: "rtmp://rtmp-api.facebook.com:80/rtmp/", andStreamKey: "\(streamPath)?\(query)")
                self.delegate.liveVideo(self, didStartWith:self.session)
            }
        }
    }
    
    func stop() {
        guard FBSDKAccessToken.current().hasGranted("publish_actions") else {
            return self.delegate.liveVideo(self, didAbortWith: FBSDKLiveVideo.errorFromDescription(description: "The \"publish_actions\" permission has not been granted"))
        }

        let graphRequest = FBSDKGraphRequest(graphPath: "/\(self.audience)/live_videos", parameters: ["end_live_video":  true], httpMethod: "POST")
        
        DispatchQueue.main.async {
            _ = graphRequest?.start { (_, _, error) in
                guard error == nil else {
                    return self.delegate.liveVideo(self, didAbortWith: FBSDKLiveVideo.errorFromDescription(description: "Error stopping the live video session: \(String(describing: error?.localizedDescription))"))
                }
                self.session.endRtmpSession()
                self.delegate.liveVideo(self, didStopWith:self.session)
            }
        }
    }
    
    // MARK: Utilities
    
    internal class func errorFromDescription(description: String) -> Error {
        return NSError(domain: FBSDKErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : description])
    }
    
    internal func updateLiveStreamParameters(with parameter: FBSDKLiveVideoParameter) {
        self.parameters[parameter.key] = parameter.value
    }
}

extension FBSDKLiveVideo : VCSessionDelegate {
    public func connectionStatusChanged(_ sessionState: VCSessionState) {
        if sessionState == .started {
            self.isStreaming = true
        } else if sessionState == .ended || sessionState == .error {
            self.isStreaming = false
        }
        
        self.delegate.liveVideo(self, didChange: sessionState)
    }
    
    public func didAddCameraSource(_ session: VCSimpleSession!) {
        self.delegate.liveVideo(self, didAdd: session)
    }
}

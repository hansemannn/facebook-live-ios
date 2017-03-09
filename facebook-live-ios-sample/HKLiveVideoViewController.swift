//
//  ViewController.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 08.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

class HKLiveVideoViewController: UIViewController {
            
    var blurOverlay: UIVisualEffectView!

    var sessionURL: NSURL!
    
    var loader: UIActivityIndicatorView!
    
    var loginButton: FBSDKLoginButton!
    
    var liveVideo: FBSDKLiveVideoService!
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordButtonTapped() {
        if !self.liveVideo.isStreaming {
            startStreaming()
        } else {
            stopStreaming()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.liveVideo = FBSDKLiveVideoService(delegate: self, frameSize: self.view.bounds, videoSize: CGSize(width: 1280, height: 720))
        self.liveVideo.privacy = .me
        self.liveVideo.audience = "me" // or your user-id, page-id, event-id, group-id, ...
        
        initializeUserInterface()
    }
    
    func initializeUserInterface() {
        self.loader = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        self.loader.frame = CGRect(x: 15, y: 15, width: 40, height: 40)
        
        self.blurOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.blurOverlay.frame = self.view.bounds
        
        self.view.insertSubview(self.liveVideo.preview, at: 0)

        self.loginButton = FBSDKLoginButton()
        self.loginButton.publishPermissions = ["publish_actions"]
        self.loginButton.loginBehavior = .native
        self.loginButton.center = CGPoint(x: self.view.bounds.size.width / 2, y: 60)
        self.loginButton.delegate = self
        self.view.addSubview(self.loginButton)

        if FBSDKAccessToken.current() == nil {
            self.view.insertSubview(self.blurOverlay, at: 1)
        } else {
            self.recordButton.isHidden = false
        }
    }
    
    func startStreaming() {
        self.liveVideo.start()

        self.loader.startAnimating()
        self.recordButton.addSubview(self.loader)
        self.recordButton.isEnabled = false
    }
    
    func stopStreaming() {
        self.liveVideo.stop()
    }
}

extension HKLiveVideoViewController : FBSDKLiveVideoDelegate {
    
    func liveVideo(didStartWithSession session: VCSimpleSession) {
        self.loader.stopAnimating()
        self.loader.removeFromSuperview()
        self.recordButton.isEnabled = true
       
        self.recordButton.imageView?.image = UIImage(named: "stop-button")
    }
    
    func liveVideo(didStopWithSession session: VCSimpleSession) {
        self.recordButton.imageView?.image = UIImage(named: "record-button")
    }
    
    func liveVideo(didAbortWithError error: Error) {
        self.recordButton.imageView?.image = UIImage(named: "record-button")
    }
}

extension HKLiveVideoViewController : FBSDKLoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        self.recordButton.isHidden = true
        self.view.insertSubview(self.blurOverlay, at: 1)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print("Error logging in: \(error.localizedDescription)")
            return
        }
        
        self.recordButton.isHidden = false
        self.blurOverlay.removeFromSuperview()
    }
}

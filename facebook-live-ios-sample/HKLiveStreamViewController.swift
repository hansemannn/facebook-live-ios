//
//  ViewController.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 08.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

class HKLiveStreamViewController: UIViewController {
        
    var previewLayer: HKVideoPreviewLayer!
    
    var blurOverlay: UIVisualEffectView!

    var sessionURL: NSURL!
    
    var loginButton: HKLoginButton!
    
    var liveVideo: FBSDKLiveVideoService!
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordButtonTapped() {
        startStreaming()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.liveVideo = FBSDKLiveVideoService(delegate: self, size: self.view.bounds.size)
        self.liveVideo.privacy = .me
        
        initializeUserInterface()
    }
    
    func initializeUserInterface() {
        self.blurOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.blurOverlay.frame = self.view.bounds
        
        self.previewLayer = HKVideoPreviewLayer()
        self.previewLayer.frame = self.view.bounds
        self.previewLayer.isVisible = true
        self.view.layer.insertSublayer(self.previewLayer, at: 0)

        self.loginButton = HKLoginButton()
        self.loginButton.initializeProperties(center: CGPoint(x: self.view.bounds.size.width / 2, y: 60))
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
    }
    
    func stopStreaming() {
        self.liveVideo.stop()
    }
    
    func hidePreviewLayer() {
        self.previewLayer.removeFromSuperlayer()
        self.blurOverlay.removeFromSuperview()
        
        self.previewLayer.isVisible = true
    }
}

extension HKLiveStreamViewController : FBSDKLiveStreamDelegate {
    
    func liveStream(didStartWithSession session: VCSimpleSession) {
        
    }
    
    func liveStream(didStopWithSession session: VCSimpleSession) {
        
    }
}

extension HKLiveStreamViewController : FBSDKLoginButtonDelegate {
    
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

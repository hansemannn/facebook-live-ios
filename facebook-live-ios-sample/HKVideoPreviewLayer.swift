//
//  HKVideoPreviewLayer.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 08.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

open class HKVideoPreviewLayer: AVCaptureVideoPreviewLayer {

    let captureSesssion: AVCaptureSession!
    var isVisible: Bool = false

    override init() {
        captureSesssion = AVCaptureSession()
        captureSesssion.sessionPreset = AVCaptureSessionPreset1920x1080

        let photoOutput = AVCapturePhotoOutput()
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSesssion.canAddInput(input) {
                captureSesssion.addInput(input)
                
                if captureSesssion.canAddOutput(photoOutput) {
                    captureSesssion.addOutput(photoOutput)
                    captureSesssion.startRunning()
                }
            }
        } catch {
            print("Error occurred: Could not attach to device input!")
        }
        
        super.init(session: captureSesssion)
        
        self.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

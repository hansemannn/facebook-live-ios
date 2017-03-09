//
//  HKLoginButoon.swift
//  facebook-live-ios-sample
//
//  Created by Hans Knoechel on 09.03.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit

@IBDesignable
class HKLoginButton: FBSDKLoginButton {

    // FIXME: This is super ugly, but for some reasom I cannot get the custom init to work
    func initializeProperties(center: CGPoint) {
        self.publishPermissions = ["publish_actions"]
        self.loginBehavior = .native
        self.center = center
    }    
}

# <img src="./assets/facebook-live-logo.png" width="30" alt="" />&nbsp;Facebook Live iOS
A custom Swift utility "FBSDKLiveVideo" to stream Facebook Live videos on iOS.

## Example
The following example would create a full-screen live video preview that is started when the user taps
the trigger button linked in your Storyboard.

```swift 
class ViewController: UIViewController {
    
    var liveVideo: FBSDKLiveVideoService!

    override func viewDidLoad() {
        super.viewDidLoad()
      
        // Create the live video service
        liveVideo = FBSDKLiveVideoService(
            delegate: self,
            frameSize: self.view.bounds,
            videoSize: CGSize(width: 1280, height: 720)
        )
        
        // Optional: Configure the live-video (see the source for all options)
        liveVideo.privacy = .me // or .friends, .friendsOfFriends, .custom
        liveVideo.audience = "me" // or your user-id, page-id, event-id, group-id, ...
        
        // Optional: Add the preview view of the stream to your container view.
        myView.addSubView(liveVideo.preview)
    }
    
    @IBAction func recordButtonTapped() {
        liveVideo.start()
    }    
}

extension ViewController: FBSDKLiveVideoDelegate {
    func liveVideo(didStartWithSession session: VCSimpleSession) {
        // Live video started
    }

    func liveVideo(didStopWithSession session: VCSimpleSession) {
        // Live video ended
    }

    func liveVideo(didAbortWithError error: Error) {
        // Live video aborted
    }
}
```

## Build
* Run `pod install` to install the required dependencies (Facebook SDK + VideoCore)
* Open the `facebook-live-ios-sample.xcworkspace` file in Xcode
* Change the app-id inside the `Info.plist` to match your app. Ensure to configure the App-ID correctly
* Run the project on your iOS device! By default, it will only start a live-stream to your private audience ("Only me")

## License
Apache 2.0 - Try it out, modify it, use it!

## Author
Hans Knöchel ([@hansemannnn](https://twitter.com/hansemannnn))

## Contributions
Code contributions are greatly appreciated, please submit a new [Pull Request](https://github.com/hansemannn/facebook-live-ios/pull/new/master)!

//
//  ViewController.swift
//  HLSInterstitialPrototype
//
//  Created by Morgan Jones on 4/13/22.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var containerView:UIView?
    @IBOutlet weak var consoleText:UITextView?
    @IBOutlet weak var consoleLabel:UILabel?
    var eventsObserver:NSObjectProtocol?
    var currentEventObserver:NSObjectProtocol?
    var newErrorObserver:NSObjectProtocol?
    var streamPlayer:AVPlayer?
    var observation: NSKeyValueObservation?
    @objc dynamic var playerItem:AVPlayerItem?
    @objc dynamic var monitor:AVPlayerInterstitialEventMonitor?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "First Screen"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupAVPlayer()
    }
    
    func setupAVPlayer() {
        
        
        //https://edgecast-cf-prod.yahoo.net/yxslive-defender-archive-oregon/archive/3d73a3f0-b468-11ec-acbf-6c76662f6b0b/hls/1080p/playlist-eg2.m3u8
        //http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8
        //https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4
 
        // playlist-eg1-1.m3u8  X-RESTRICT="SKIP,JUMP"
        // playlist-eg1-2.m3u8  X-RESTRICT="JUMP"
        // playlist-eg2-2.m3u8  no X-RESTRICT
        // playlist-eg3-2.m3u8  X-PLAYOUT-LIMIT=15.0,X-RESTRICT="SKIP,JUMP"
        // playlist-eg4-4.m3u8  X-ASSET-LIST both asset/ads break contain empty ads
        // playlist-eg4-6.m3u8  X-ASSET-LIST First asset contains an ad, Second asset is empty
        // playlist-eg5.m3u8    X-ASSET-LIST First asset contains an ad

        if let url = URL.init(string: "https://edgecast-cf-prod.yahoo.net/yxslive-defender-archive-oregon/archive/3d73a3f0-b468-11ec-acbf-6c76662f6b0b/hls/1080p/playlist-eg1-2.m3u8") { // TODO:  Change me!
            
            
            addMessage("-----> IE: building player...\n")
            let asset = AVURLAsset(url: url, options: nil)
            playerItem = AVPlayerItem(asset: asset)
            
            // KeyValue observing the AVPlayer Status change to log playlist errors
            observation = observe(
                \.playerItem!.status,
                 options: [.old, .new]
            ) { [self] object, change in
                if let theItem = object.playerItem {
                    self.addMessage("-----> player status changed \(theItem.status)")
                    if theItem.status == AVPlayerItem.Status.failed, let theError = theItem.error {
                        self.handlePlayerError(theError)
                    }
                }
            }
            
            let aPlayer = AVPlayer.init(playerItem: playerItem)
            
            // This Event Monitor is not currently working
            // I have questions pending, once I hear something I revisit.
            
            newErrorObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry,
                                                   object: playerItem,
                                                   queue: OperationQueue.main) { notification in
                if let object = notification.object, let aPlayerItem = object as? AVPlayerItem, let errorLog = aPlayerItem.errorLog() {
                    self.addMessage("-----> newErrorLogEntry: \(errorLog)\n")
                }
            }
            
            monitor = AVPlayerInterstitialEventMonitor(primaryPlayer: aPlayer)
            eventsObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerInterstitialEventMonitor.eventsDidChangeNotification,
                object: monitor,
                queue: OperationQueue.main) { notification in
                    self.addMessage("-----> IE eventsDidChange: /(notification)\n")
                }
            
            currentEventObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerInterstitialEventMonitor.currentEventDidChangeNotification,
                object: monitor,
                queue: OperationQueue.main) { notification in
                    self.addMessage("-----> IE currentEventsDidChange: /(notification)\n")
                }
            
            //streamPlayer = aPlayer
            
            let avPlayerViewController = AVPlayerViewController()
            avPlayerViewController.player = aPlayer
            if let containerFrame = containerView?.frame {
                avPlayerViewController.view.frame = CGRect(x: 0, y: containerFrame.origin.y, width: self.view.frame.size.width, height: self.view.frame.size.width * 9/16)
                self.addChild(avPlayerViewController)
                self.view.addSubview(avPlayerViewController.view)
                avPlayerViewController.didMove(toParent: self)
            }

            aPlayer.play()
            addMessage("-----> Play\n")

        } else {
            addMessage("-----> URL Error\n")
        }
        
    }
    
    func addMessage(_ newMessage:String) {
        
        consoleText?.text.append(newMessage)
    }
    
    func handlePlayerError(_ error:Error) {
        
        let theError = error as NSError
        let errorDescription = theError.debugDescription
        
        addMessage("-----> '\(errorDescription)'\n")
    }
}


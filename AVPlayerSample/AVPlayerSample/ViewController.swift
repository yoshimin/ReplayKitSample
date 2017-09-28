//
//  ViewController.swift
//  ReplayKitSample
//

import UIKit
import ReplayKit

class ViewController: UIViewController {
    let assetWriter = AssetWriter(fileName: "test.mp4")
    
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.path(forResource: "sample", ofType: "mp4") {
            let item = AVPlayerItem(url: URL(fileURLWithPath: path))
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            
            player = AVPlayer(playerItem: item)
            
            if let playerLayer = view.layer as? AVPlayerLayer {
                playerLayer.player = player
            }
            
            player?.play()
            startCapture()
        }
    }
    
    func playerDidFinishPlaying() {
        stopCapture()
    }
}

extension ViewController {
    func startCapture() {
        RPScreenRecorder.shared().startCapture(handler: { (buffer, bufferType, err) in
            self.assetWriter.write(buffer: buffer, bufferType: bufferType)
        }, completionHandler: {
            if let error = $0 {
                print(error)
            }
        })
    }
    
    func stopCapture() {
        RPScreenRecorder.shared().stopCapture {
            if let err = $0 {
                print(err)
            }
            self.assetWriter.finishWriting()
        }
    }
}


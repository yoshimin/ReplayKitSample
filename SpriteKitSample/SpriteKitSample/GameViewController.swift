//
//  GameViewController.swift
//  SpriteKitSample
//
//  Created by Shingai Yoshimi on 2017/09/28.
//  Copyright © 2017年 Shingai Yoshimi. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import ReplayKit

class GameViewController: UIViewController {
    @IBOutlet var captureButton: UIButton!
    
    let assetWriter = AssetWriter(fileName: "test.mp4")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func toggleCapturing(_ sender: Any) {
        if captureButton.isSelected {
            stopCapture()
            captureButton.setTitle("録画", for: .normal)
        } else {
            startCapture()
            captureButton.setTitle("停止", for: .normal)
        }
        captureButton.isSelected = !captureButton.isSelected
    }
    
}

extension GameViewController {
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

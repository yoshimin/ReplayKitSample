//
//  GameViewController.swift
//  MetalSample
//
//  Created by Shingai Yoshimi on 2017/09/29.
//  Copyright © 2017年 Shingai Yoshimi. All rights reserved.
//

import UIKit
import MetalKit
import ReplayKit

// Our iOS specific view controller
class GameViewController: UIViewController {
    @IBOutlet var captureButton: UIButton!
    
    let assetWriter = AssetWriter(fileName: "test.mp4")
    
    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        
        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.clear

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
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
        RPScreenRecorder.shared().isMicrophoneEnabled = true
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


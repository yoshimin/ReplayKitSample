//
//  PlayerView.swift
//  ReplayKitSample
//

import UIKit
import AVFoundation

class PlayerView : UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

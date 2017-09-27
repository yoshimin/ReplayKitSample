//
//  ViewController.swift
//  ReplayKitSample
//

import UIKit
import ReplayKit

class ViewController: UIViewController {
    // MARK: Properties
    var assetWriter: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    var videoWidth = 0
    var videoHeight = 0
    
    let writeQueue = DispatchQueue(label: "writeQueue")
    
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
        self.stopCapture()
    }
}

extension ViewController {
    func startCapture() {
        RPScreenRecorder.shared().startCapture(handler: { (buffer, bufferType, err) in
            self.write(buffer: buffer, bufferType: bufferType)
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
            self.finishWriting()
        }
    }
}

extension ViewController {
    func setupWriter(buffer: CMSampleBuffer) {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var path = dir + "/ReplayKitSample"
        
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("fail to removeItem")
            }
        }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("fail to createDirectory")
        }
        
        path += "/sample.mp4"
        self.assetWriter = try? AVAssetWriter(outputURL: URL(fileURLWithPath: path), fileType: AVFileTypeQuickTimeMovie)
        
        let writerOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoWidth,
            AVVideoHeightKey: videoHeight,
            ] as [String : Any]
        
        self.videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: writerOutputSettings)
        self.videoInput?.expectsMediaDataInRealTime = true
        
        guard let format = CMSampleBufferGetFormatDescription(buffer),
            let stream = CMAudioFormatDescriptionGetStreamBasicDescription(format) else {
                print("fail to setup audioInput")
                return
        }
        
        let audioOutputSettings = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : stream.pointee.mChannelsPerFrame,
            AVSampleRateKey : stream.pointee.mSampleRate,
            AVEncoderBitRateKey : 64000
            ] as [String : Any]
        
        self.audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        self.audioInput?.expectsMediaDataInRealTime = true
        
        if let videoInput = self.videoInput, (self.assetWriter?.canAdd(videoInput))! {
            self.assetWriter?.add(videoInput)
        }
        
        if  let audioInput = self.audioInput, (self.assetWriter?.canAdd(audioInput))! {
            self.assetWriter?.add(audioInput)
        }
    }
    
    func write(buffer: CMSampleBuffer, bufferType: RPSampleBufferType) {
        writeQueue.sync {
            if assetWriter == nil {
                if videoWidth == 0 && videoHeight == 0 && bufferType == .video {
                    if let imageBuffer = CMSampleBufferGetImageBuffer(buffer) {
                        videoWidth = CVPixelBufferGetWidth(imageBuffer)
                        videoHeight = CVPixelBufferGetHeight(imageBuffer)
                    }
                    return
                }
                
                if bufferType == .audioApp {
                    setupWriter(buffer: buffer)
                }
            }
            
            if assetWriter == nil {
                return
            }
            
            if self.assetWriter?.status == .unknown {
                print("Start writing")
                let startTime = CMSampleBufferGetPresentationTimeStamp(buffer)
                self.assetWriter?.startWriting()
                self.assetWriter?.startSession(atSourceTime: startTime)
            }
            if self.assetWriter?.status == .failed {
                print("assetWriter status: failed error: \(String(describing: self.assetWriter?.error))")
                return
            }
            
            if CMSampleBufferDataIsReady(buffer) == true {
                if bufferType == .video {
                    if let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData {
                        videoInput.append(buffer)
                    }
                } else if bufferType == .audioApp {
                    if let audioInput = self.audioInput, audioInput.isReadyForMoreMediaData {
                        audioInput.append(buffer)
                    }
                }
            }
        }
    }
    
    func finishWriting() {
        writeQueue.sync {
            self.assetWriter?.finishWriting(completionHandler: {
                print("finishWriting")
            })
        }
    }
}


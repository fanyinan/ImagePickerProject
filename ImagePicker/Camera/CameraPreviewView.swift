//
//  CameraPreviewView.swift
//  ImagePickerProject
//
//  Created by 范祎楠 on 16/7/6.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import AVFoundation
import UIKit

class CameraPreviewView: UIView {

  fileprivate var inputVideo: AVCaptureDeviceInput!
  fileprivate var preLayer: AVCaptureVideoPreviewLayer!
  fileprivate var session: AVCaptureSession!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    initRecording()
  }

  required init?(coder aDecoder: NSCoder) {

    super.init(coder: aDecoder)
    
    initRecording()

  }
  
  override func layoutSubviews() {
    
    preLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

  }
  
  func startPreview() {
    
    DispatchQueue.global().async {
      
      self.session.startRunning()
      
    }
    
  }
  
  func stopPreview() {
  
    DispatchQueue.global().async {
      
      self.session.stopRunning()
      
    }
    
  }
  
  fileprivate func initRecording() {
    
    guard let device = getCamera(with: .back) else {
      print("初始化录制设备失败")

      return
    }
    
    do {
      
      inputVideo = try AVCaptureDeviceInput(device: device)
      
    } catch {
      
      print("初始化录制设备失败")
      
    }
    
    session = AVCaptureSession()
    
    if session.canAddInput(inputVideo) {
      session.addInput(inputVideo)
    }
    
    preLayer = AVCaptureVideoPreviewLayer(session: session)
    preLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    layer.addSublayer(preLayer)
    
  }

  fileprivate func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    
    for device in AVCaptureDevice.devices(for: AVMediaType.video) {
      
      if device.position == position {
        return device
      }
    }
    
    return nil
  }
  
}

//
//  CameraPreviewView.swift
//  ImagePickerProject
//
//  Created by 范祎楠 on 16/7/6.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import AVFoundation

class CameraPreviewView: UIView {

  private var inputVideo: AVCaptureDeviceInput!
  private var preLayer: AVCaptureVideoPreviewLayer!
  private var session: AVCaptureSession!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    initRecording()
  }
  
  required init?(coder aDecoder: NSCoder) {

    super.init(coder: aDecoder)
    
    initRecording()

  }
  
  override func layoutSubviews() {
    
    let sreenSize = UIScreen.mainScreen().bounds.size
    preLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

  }
  
  func startPreview() {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { 
      
      self.session.startRunning()
      
    }
    
  }
  
  func stopPreview() {
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
      
      self.session.stopRunning()
      
    }
    
  }
  
  private func initRecording() {
    
    let device = getCamera(with: .Back)
    
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
    preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    layer.addSublayer(preLayer)
    
  }

  private func getCamera(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
    
    for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
      
      let device = device as! AVCaptureDevice
      
      if device.position == position {
        return device
      }
    }
    
    return nil
  }
  
}

//
//  ImageUploadViewController.swift
//
//
//  Created by 范祎楠 on 15/4/23.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit
import Photos

public protocol WZImagePickerDelegate: NSObjectProtocol {
  
  func pickedPhoto(_ imagePickerHelper: WZImagePickerHelper, didPickResource resource: WZResourceType)
  func pickedPhoto(_ imagePickerHelper: WZImagePickerHelper, shouldPickResource resource: WZResourceType) -> Bool
  
}

public extension WZImagePickerDelegate {
  
  func pickedPhoto(_ imagePickerHelper: WZImagePickerHelper, didPickResource resource: WZResourceType) {}
  func pickedPhoto(_ imagePickerHelper: WZImagePickerHelper, shouldPickResource resource: WZResourceType) -> Bool { return true }
  
}

public enum WZImagePickerType {
  case album
  case camera
  case albumAndCamera
}

 public struct WZResourceOption: OptionSet {
  public var rawValue: Int = 0
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  public static var image = WZResourceOption(rawValue: 1 << 0)
  public static var video = WZResourceOption(rawValue: 1 << 1)
  public static var data = WZResourceOption(rawValue: 1 << 2)
}

public enum WZResourceType {
  case image(images: [UIImage])
  case video(video: AVAsset?)
  case rawImageData(imageData: Data?)
}

open class WZImagePickerHelper: NSObject {
  
  private var cameraHelper: CameraHelper!
  private weak var handlerViewController: UIViewController?
  
  public weak var delegate: WZImagePickerDelegate?
  public var maxSelectedCount: Int = 1
  public var isCrop: Bool = false
  public var type: WZImagePickerType = .albumAndCamera
  public var resourceOption: WZResourceOption = .image
  
  public init(delegate: WZImagePickerDelegate?, handlerViewController: UIViewController? = nil) {
    self.delegate = delegate
    self.handlerViewController = handlerViewController ?? (delegate as! UIViewController)
    self.maxSelectedCount = 1
    super.init()
    
    PhotosManager.sharedInstance.clearData()
  }

  /******************************************************************************
   *  public Method Implementation
   ******************************************************************************/
  //MARK: - public Method Implementation
  
  public func start(){
    
    guard let _handlerViewController = handlerViewController else { return }
    
    if resourceOption == .video {
      maxSelectedCount = 1
    }
    
    if maxSelectedCount <= 0 {
      maxSelectedCount = 1
    }
    
    if maxSelectedCount > 1 {
      isCrop = false
    }
    
    PhotosManager.sharedInstance.prepare(self)
    
    if type == .camera {
      
      if resourceOption.contains(.image) {
        cameraHelper = CameraHelper(handlerViewController: _handlerViewController)
        cameraHelper.isCrop = isCrop
        cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Present
        cameraHelper.openCamera()
      } else if resourceOption.contains(.video) {
        
      }
      
    } else {
      
      openAblum()
      
    }
  }
  
  func onComplete(_ resource: WZResourceType?) {
    
    if let resource = resource {
      
      guard shouldPick(resource: resource) else { return }
      
      finish(with: resource)
      return
    }
    
    if let _ = PhotosManager.sharedInstance.selectedVideo  {
      fetchVideo()
      return
    }
    
    if resourceOption.contains(.data) && PhotosManager.sharedInstance.selectedImages.count == 1 {
      fetchImageDatas()
    } else {
      fetchImages()
    }
  }
  
  private func shouldPick(resource: WZResourceType) -> Bool {
    
    let should = delegate?.pickedPhoto(self, shouldPickResource: resource) ?? true
    
    if !should {
      PhotosManager.sharedInstance.removeSelectionIfMaxCountIsOne()
    }
    
    return should
  }
  
  private func finish(with resource: WZResourceType) {
    
    handlerViewController?.dismiss(animated: true, completion: {
      
      PhotosManager.sharedInstance.clearData()
      
      self.delegate?.pickedPhoto(self, didPickResource: resource)
      
    })
  }
  
  private func fetchVideo() {
    
    PhotosManager.sharedInstance.fetchVideo(handleCompletion: { avAsset in
      
      let resource: WZResourceType = .video(video: avAsset)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
      
    })
  }
  
  private func fetchImageDatas() {
    
    PhotosManager.sharedInstance.fetchSelectedImageData({ (data, isGIF) in
      
      var resource: WZResourceType!
      
      //在选了.data的情况下，是gif时，一定返回data
      //如果不是gif，若选了.image则返回image, 否则返回data
      
      if !isGIF && self.resourceOption.contains(.image) {
        guard let data = data, let image = UIImage(data: data) else { return }
        resource = .image(images: [image])
      } else {
        resource = .rawImageData(imageData: data)
      }
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
      
    })
  }
  
  private func fetchImages() {
    
    PhotosManager.sharedInstance.fetchSelectedImages { (images) -> Void in
      
      let resource: WZResourceType = .image(images: images)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
    }
  }
  
  private func openAblum() {
    
    guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
      
      let _ = UIAlertView(title: "相册不可用", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
      
      return
    }
    
    let status = PHPhotoLibrary.authorizationStatus()
    
    switch status {
    case .notDetermined:
      
      PHPhotoLibrary.requestAuthorization { (status) in
        
        guard status == .authorized else { return }
        
        DispatchQueue.main.async {
          self.showAblum()
        }

      }
      
    case .authorized:
      showAblum()
      
    case .restricted, .denied:
      
      let _ = UIAlertView(title: "相册被禁用", message: "请在设置－隐私－照片中开启", delegate: nil, cancelButtonTitle: "确定").show()
      
    }
  }
  
  private func showAblum() {
    
    let viewController = PhotoColletionViewController()
    viewController.canOpenCamera = self.type != .album
    
    let navigationController = UINavigationController(rootViewController: viewController)
    navigationController.navigationBar.isTranslucent = false
    navigationController.navigationBar.tintColor = .jx_main
    self.handlerViewController?.present(navigationController, animated: true, completion: nil)
    
  }
}

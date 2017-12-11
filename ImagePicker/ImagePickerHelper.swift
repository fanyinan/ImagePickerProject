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
  case video(videos: [AVAsset])
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
    
  }
  
  /******************************************************************************
   *  public Method Implementation
   ******************************************************************************/
  //MARK: - public Method Implementation
  
  open func start() {
    
    guard let _handlerViewController = handlerViewController else { return }
    
    if maxSelectedCount <= 0 {
      maxSelectedCount = 1
    }
    
    if maxSelectedCount > 1 {
      isCrop = false
    }
    
    PhotosManager.shared.prepare(self)
    
    if type == .camera {
      
      if resourceOption.contains(.image) {
        cameraHelper = CameraHelper(handlerViewController: _handlerViewController)
        cameraHelper.isCrop = isCrop
        cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Present
        cameraHelper.openCamera()
      } else if resourceOption.contains(.video) {
        
      }
      
    } else {
      
      showAblum()
      
    }
  }
  
  func onComplete(_ resource: WZResourceType?) {
    
    if let resource = resource {
      
      guard shouldPick(resource: resource) else { return }
      
      finish(with: resource)
      return
    }
    
    if !PhotosManager.shared.selectedVideos.isEmpty  {
      fetchVideo()
      return
    }
    
    if resourceOption.contains(.data) && PhotosManager.shared.selectedImages.count == 1 {
      fetchImageDatas()
    } else {
      fetchImages()
    }
  }
  
  private func shouldPick(resource: WZResourceType) -> Bool {
    
    let should = delegate?.pickedPhoto(self, shouldPickResource: resource) ?? true
    
    if !should {
      PhotosManager.shared.removeSelectionIfMaxCountIsOne()
    }
    
    return should
  }
  
  private func finish(with resource: WZResourceType) {
    
    handlerViewController?.dismiss(animated: true, completion: {
      
      PhotosManager.shared.clearData()
      
      self.delegate?.pickedPhoto(self, didPickResource: resource)
      
    })
  }
  
  private func fetchVideo() {
    
    PhotosManager.shared.fetchSelectedVideos(handleCompletion: { avAsset in
      
      let resource: WZResourceType = .video(videos: avAsset)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
      
    })
  }
  
  private func fetchImageDatas() {
    
    PhotosManager.shared.fetchSelectedImageData({ (data, isGIF) in
      
      var resource: WZResourceType!
      
      //在选了.data的情况下，是gif时，一定返回data
      //如果不是gif，若选了.image则返回image, 否则返回data
      
      if !isGIF && self.resourceOption.contains(.image) {
        guard let data = data, let image = UIImage(data: data) else { return }
        
        var images: [UIImage] = [image]
        
        if self.isCrop {
          images = [PhotosManager.shared.cropImage(image)]
        }
        
        resource = .image(images: images)
        
      } else {
        
        resource = .rawImageData(imageData: data)
        
      }
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
      
    })
  }
  
  private func fetchImages() {
    
    PhotosManager.shared.fetchSelectedImages { (images) -> Void in
      
      var images: [UIImage] = images
      
      if self.isCrop && images.count == 1 {
        images = [PhotosManager.shared.cropImage(images[0])]
      }
      
      let resource: WZResourceType = .image(images: images)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
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


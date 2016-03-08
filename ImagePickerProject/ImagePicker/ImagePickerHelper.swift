//
//  ImageUploadViewController.swift
//
//
//  Created by 范祎楠 on 15/4/23.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit
import Photos

protocol ImagePickerDelegate: NSObjectProtocol {
  
  func pickedPhoto(imagePickerHelper: ImagePickerHelper, images: [UIImage])
  
}

enum ImagePickerType {
  case Album
  case Camera
  case AlbumAndCamera
}

class ImagePickerHelper: NSObject {
  
  private var cameraHelper: CameraHelper!
  
  weak var delegate: ImagePickerDelegate?
  weak var handlerViewController: UIViewController?
  //最大图片数量，default ＝ 1
  var maxSelectedCount: Int {
    didSet {
      PhotosManager.sharedInstance.maxSelectedCount = maxSelectedCount
    }
  }
  
  //是否裁剪
  var isCrop: Bool = false {
    didSet{
      PhotosManager.sharedInstance.isCrop = isCrop
    }
  }
  var type: ImagePickerType = .AlbumAndCamera
  
  init(delegate: ImagePickerDelegate, handlerViewController: UIViewController? = nil){
    self.delegate = delegate
    self.handlerViewController = handlerViewController ?? (delegate as! UIViewController)
    self.maxSelectedCount = 1
    super.init()
    
  }
  
  deinit{
    print("ImagePickerHelper deinit")
  }
  
  /******************************************************************************
   *  public Method Implementation
   ******************************************************************************/
   //MARK: - public Method Implementation
  
  func startPhoto(){
    
    PhotosManager.sharedInstance.clearData()
    
    guard let _handlerViewController = handlerViewController else { return }
    
    
    PhotosManager.sharedInstance.prepareWith(self)
    
    if type == .Camera {
      
      cameraHelper = CameraHelper(handlerViewController: _handlerViewController)
      cameraHelper.isCrop = PhotosManager.sharedInstance.isCrop
      cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Present
      cameraHelper.openCamera()
      
    } else {
      
      openAblum()
      
    }
  }
  
  
  func onComplete(image: UIImage?) {
    
    if let image = image {
      self.delegate?.pickedPhoto(self, images: [image])
      
      self.handlerViewController?.dismissViewControllerAnimated(true, completion: nil)
      
      return
    }
    
    PhotosManager.sharedInstance.fetchSelectedImages { (images) -> Void in
      
      self.handlerViewController?.dismissViewControllerAnimated(true, completion: nil)
      
      self.delegate?.pickedPhoto(self, images: images)
      
    }
    
    
  }
  
  private func openAblum() {
    
    let status = PHPhotoLibrary.authorizationStatus()
    
    guard status != .Restricted && status != .Denied else {
      
      let _ = UIAlertView(title: "相册被禁用", message: "请在设置－隐私－照片中开启", delegate: nil, cancelButtonTitle: "确定").show()
      
      return
    }
    
    guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
      
      let _ = UIAlertView(title: "相册不可用", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
      
      return
    }
    
    let viewController = PhotoAlbumViewController()
    viewController.canOpenCamera = type != .Album
    
    let navigationController = UINavigationController(rootViewController: viewController)
    navigationController.navigationBar.translucent = false
    handlerViewController?.presentViewController(navigationController, animated: true, completion: nil)
    
  }
}

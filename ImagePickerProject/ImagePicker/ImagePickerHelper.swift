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
  
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, images: [UIImage])
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, didPickResource resource: ResourceType)
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, shouldPickResource resource: ResourceType) -> Bool
}

extension ImagePickerDelegate {
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, images: [UIImage]) {}
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, didPickResource resource: ResourceType) {}
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, shouldPickResource resource: ResourceType) -> Bool { return true }
}

enum ImagePickerType {
  case album
  case camera
  case albumAndCamera
}

struct ResourceOption: OptionSet {
  var rawValue: Int = 0
  static var image = ResourceOption(rawValue: 1 << 0)
  static var video = ResourceOption(rawValue: 1 << 1)
  static var data = ResourceOption(rawValue: 1 << 2)
}

enum ResourceType {
  case image(images: [UIImage])
  case video(video: AVAsset?)
  case rawImageData(imageData: Data?)
}

class ImagePickerHelper: NSObject {
  
  fileprivate var cameraHelper: CameraHelper!
  
  weak var delegate: ImagePickerDelegate?
  weak var handlerViewController: UIViewController?
  //最大图片数量，default ＝ 1
  var maxSelectedCount: Int {
    didSet {
      PhotosManager.sharedInstance.maxSelectedCount = max(1, maxSelectedCount)
    }
  }
  
  //是否裁剪
  var isCrop: Bool = false {
    didSet{
      PhotosManager.sharedInstance.isCrop = isCrop
    }
  }
  var type: ImagePickerType = .albumAndCamera
  var resourceOption: ResourceOption = .image {
    didSet{
      PhotosManager.sharedInstance.resourceOption = resourceOption
    }
  }
  
  init(delegate: ImagePickerDelegate, handlerViewController: UIViewController? = nil){
    self.delegate = delegate
    self.handlerViewController = handlerViewController ?? (delegate as! UIViewController)
    self.maxSelectedCount = 1
    super.init()
    
    PhotosManager.sharedInstance.clearData()
  }
  
  deinit{
    print("ImagePickerHelper deinit")
  }
  
  /******************************************************************************
   *  public Method Implementation
   ******************************************************************************/
  //MARK: - public Method Implementation
  
  func startPhoto(){
    
    guard let _handlerViewController = handlerViewController else { return }
    
    PhotosManager.sharedInstance.prepareWith(self)
    
    if type == .camera {
      
      cameraHelper = CameraHelper(handlerViewController: _handlerViewController)
      cameraHelper.isCrop = PhotosManager.sharedInstance.isCrop
      cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Present
      cameraHelper.openCamera()
      
    } else {
      
      openAblum()
      
    }
  }
  
  func onComplete(_ image: UIImage?) {
    
    if let image = image {
      
      guard self.delegate?.pickedPhoto(self, shouldPickResource: .image(images: [image])) ?? true else {
        PhotosManager.sharedInstance.removeSelectionIfMaxCountIsOne()
        return
      }
      
      self.handlerViewController?.dismiss(animated: true, completion: {
        
        PhotosManager.sharedInstance.clearData()
        
        self.delegate?.pickedPhoto(self, images: [image])
        
      })
      
      return
    }
    
    if let _ = PhotosManager.sharedInstance.selectedVideo {
      
      PhotosManager.sharedInstance.fetchVideo(handleCompletion: { avAsset in
        
        guard self.delegate?.pickedPhoto(self, shouldPickResource: .video(video: avAsset)) ?? true else {
          PhotosManager.sharedInstance.removeSelectionIfMaxCountIsOne()
          return
        }
        
        self.handlerViewController?.dismiss(animated: true, completion: {
          PhotosManager.sharedInstance.clearData()
          self.delegate?.pickedPhoto(self, didPickResource: .video(video: avAsset))
        })
      })
      
    } else {
      
      if resourceOption.contains(.data) && PhotosManager.sharedInstance.selectedImages.count == 1 {
        
        PhotosManager.sharedInstance.fetchSelectedImageData({ (data, isGIF) in
          
          guard self.delegate?.pickedPhoto(self, shouldPickResource: .rawImageData(imageData: data)) ?? true else {
            PhotosManager.sharedInstance.removeSelectionIfMaxCountIsOne()
            return
          }
          
          self.handlerViewController?.dismiss(animated: true, completion: {
            
            PhotosManager.sharedInstance.clearData()
            
            var images: [UIImage] = []
            
            if let data = data, let image = UIImage(data: data) {
              images.append(image)
            }
            
            //在选了.data的情况下，是gif时，一定返回data
            //如果不是gif，若选了.image则返回image, 否则返回data
            if isGIF {
              self.delegate?.pickedPhoto(self, didPickResource: .rawImageData(imageData: data))
            } else {
              
              if self.resourceOption.contains(.image) {
                self.delegate?.pickedPhoto(self, didPickResource: .image(images: images))
              } else {
                self.delegate?.pickedPhoto(self, didPickResource: .rawImageData(imageData: data))
              }
            }
            
            self.delegate?.pickedPhoto(self, images: images)

          })
        })
        
      } else {
       
        PhotosManager.sharedInstance.fetchSelectedImages { (images) -> Void in
          
          guard self.delegate?.pickedPhoto(self, shouldPickResource: .image(images: images)) ?? true else {
            PhotosManager.sharedInstance.removeSelectionIfMaxCountIsOne()
            return
          }
          
          self.handlerViewController?.dismiss(animated: true, completion: {
            
            PhotosManager.sharedInstance.clearData()
            
            self.delegate?.pickedPhoto(self, didPickResource: .image(images: images))
            self.delegate?.pickedPhoto(self, images: images)

          })
        }
      }
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
        
        exChangeMainQueue {
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
    navigationController.navigationBar.tintColor = mainTextColor
    self.handlerViewController?.present(navigationController, animated: true, completion: nil)
    
  }
}

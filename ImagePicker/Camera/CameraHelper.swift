//
//  CameraHelper.swift
//  Yuanfenba
//
//  Created by 范祎楠 on 16/3/3.
//  Copyright © 2016年 Juxin. All rights reserved.
//

import UIKit
import Photos

class CameraHelper: NSObject {

  static let cropViewControllerTranlateType_Push = 0
  static let cropViewControllerTranlateType_Present = 1

  fileprivate weak var handlerViewController: UIViewController?
  
  var isCrop = false
  
  //当为false时由WZImagePickerHelper来负责dismiss
  var cropViewControllerTranlateType: Int = CameraHelper.cropViewControllerTranlateType_Push
  
  var imagePicker:UIImagePickerController!

  init(handlerViewController: UIViewController) {
    
    self.handlerViewController = handlerViewController
    
  }
  
  func openCamera() {

    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      imagePicker = UIImagePickerController()
      imagePicker.sourceType = .camera
      imagePicker.cameraDevice = .front
      imagePicker.isEditing = false
      imagePicker.delegate = self
      handlerViewController?.modalPresentationStyle = .overCurrentContext
      handlerViewController?.present(imagePicker, animated: true, completion: nil)
    } else {
      let _ = UIAlertView(title: "相机不可用", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
    }
  }
}

extension CameraHelper: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    let type : String = info[UIImagePickerControllerMediaType] as! String
    
    if type == "public.image" {
      
      let image : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
      
      if isCrop {
        
        let viewController = PhotoCropViewController(image: image)
        viewController.hidesBottomBarWhenPushed = true
        
        picker.dismiss(animated: false, completion: nil)

        //这种情况dismiss，是因为外部会dismiss掉PhotoCropViewController的rootViewController
        if cropViewControllerTranlateType == CameraHelper.cropViewControllerTranlateType_Push {
          
          handlerViewController?.navigationController?.pushViewController(viewController, animated: true)

          //这种情况dismiss是因为会present出新的viewcontroller，外部会dismiss新的viewcontroller
        } else if cropViewControllerTranlateType == CameraHelper.cropViewControllerTranlateType_Present{
          
          handlerViewController?.present(viewController, animated: true, completion: nil)

        }
        
      } else {
        
        picker.dismiss(animated: false, completion: nil)
        
        PhotosManager.sharedInstance.didFinish(.image(images: [image]))
        
      }
      
    }
  }
  
}

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

  private weak var handlerViewController: UIViewController?
  
  var isCrop = false
  
  //当为false时由ImagePickerHelper来负责dismiss
  var cropViewControllerTranlateType: Int = CameraHelper.cropViewControllerTranlateType_Push
  
  var imagePicker:UIImagePickerController!

  init(handlerViewController: UIViewController) {
    
    self.handlerViewController = handlerViewController
    
  }
  
  func openCamera() {

    if UIImagePickerController.isSourceTypeAvailable(.Camera){
      imagePicker = UIImagePickerController()
      imagePicker.sourceType = .Camera
      imagePicker.cameraDevice = .Front
      imagePicker.editing = false
      imagePicker.delegate = self
      handlerViewController?.modalPresentationStyle = .OverCurrentContext
      handlerViewController?.presentViewController(imagePicker, animated: true, completion: {
        
        self.checkCamera() })
    } else {
      print("相机不可用")
    }
    
  }
  
  private func checkCamera(){
    
    let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    if (AVAuthorizationStatus.Denied == authStatus || AVAuthorizationStatus.Restricted == authStatus){
      
      let _ = UIAlertView(title: "相机被禁用", message: "请在设置－隐私－相机中开启", delegate: nil, cancelButtonTitle: "确定").show()
      
    }
  }
}

extension CameraHelper: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    
    let type : String = info[UIImagePickerControllerMediaType] as! String
    
    if type == "public.image" {
      
      let image : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
      
      if isCrop {
        
        let viewController = PhotoCropViewController(image: image)
        viewController.hidesBottomBarWhenPushed = true
        
        picker.dismissViewControllerAnimated(false, completion: nil)

        //这种情况dismiss，是因为外部会dismiss掉PhotoCropViewController的rootViewController
        if cropViewControllerTranlateType == CameraHelper.cropViewControllerTranlateType_Push {
          
          handlerViewController?.navigationController?.pushViewController(viewController, animated: true)

          //这种情况dismiss是因为会present出新的viewcontroller，外部会dismiss新的viewcontroller
        } else if cropViewControllerTranlateType == CameraHelper.cropViewControllerTranlateType_Present{
          
          handlerViewController?.presentViewController(viewController, animated: true, completion: nil)

        }
        
      } else {
        
        //这里不需要dismiss，统一让外部来dismiss
//        picker.dismissViewControllerAnimated(true, completion: nil)
        
        PhotosManager.sharedInstance.didFinish(image)
        
      }
      
    }
  }
  
//  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
//    
//  }
}
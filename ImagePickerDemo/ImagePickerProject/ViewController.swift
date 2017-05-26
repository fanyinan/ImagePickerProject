//
//  ViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet var isCropSwitch: UISwitch!
  @IBOutlet var maxCountTextField: UITextField!
  @IBOutlet var imageViews: [UIImageView]!
  
  var isCrop: Bool = true
  var type: WZImagePickerType = .albumAndCamera
  var maxCount = 3
  
  @IBAction func onStart() {
    
    let imagePickerHelper = WZImagePickerHelper(delegate: self)
    imagePickerHelper.isCrop = isCrop
    imagePickerHelper.maxSelectedCount = maxCount
    imagePickerHelper.type = type
    imagePickerHelper.resourceOption = [.image]
    imagePickerHelper.start()
  }
  
  @IBAction func onIsCrop(_ sender: UISwitch) {
    
    isCrop = sender.isOn
    
    if isCrop {
      maxCountTextField.text = "1"
      maxCount = 1
    }
    
  }
  
  @IBAction func onStyle(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      type = .albumAndCamera
    case 1:
      type = .album
    case 2:
      type = .camera
    default:
      break
    }
  }
  
  @IBAction func onCountChange(_ sender: UITextField) {
    
    guard let maxCount = Int(sender.text!) else { return }
    
    self.maxCount = maxCount
    
    if maxCount != 1 {
      isCropSwitch.setOn(false, animated: true)
    }
  }
  
}

extension ViewController: WZImagePickerDelegate {
  
  func pickedPhoto(_ imagePickerHelper: WZImagePickerHelper, didPickResource resource: WZResourceType) {
    print(#function)
    if case .video(video: let tmpAVAsset) = resource, let avAsset = tmpAVAsset {
      print(avAsset)
    }
    
    if case .rawImageData(imageData: let imageData) = resource, let _imageData = imageData {
      
      print(_imageData.count)
    }
    
    if case .image(images: let images) = resource {
      print(images.count)
      
      for (index, image) in images.enumerated() {
        
        if index >= imageViews.count {
          return
        }
        
        imageViews[index].image = image
      }
    }
  }
}


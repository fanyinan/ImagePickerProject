//
//  ViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

let separatorColor = UIColor(hex: 0xe5e5e5)

class ViewController: UIViewController {

  @IBOutlet var isCropSwitch: UISwitch!
  @IBOutlet var maxCountTextField: UITextField!
  @IBOutlet var imageViews: [UIImageView]!
  
  var isCrop: Bool = true
  var type: ImagePickerType = .albumAndCamera
  var maxCount = 3
  
  @IBAction func onStart() {
    
    let imagePickerHelper = ImagePickerHelper(delegate: self)
    imagePickerHelper.isCrop = isCrop
    imagePickerHelper.maxSelectedCount = maxCount
    imagePickerHelper.type = type
    imagePickerHelper.resourceOption = [.image, .data]
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
  
  func testCompression(image: UIImage) {
    
    printImageInfo(prefix: "raw", image: image)

    let imageDefaultSize = CGSize(width: 100, height: 100)

    let image1 = image.imageScaledWithoutCliped(to: imageDefaultSize)!
    
    printImageInfo(prefix: "size", image: image1)
    
    image1.compressForUpload { (data, image) in
      
      self.printImageInfo(prefix: "size-DataSize", image: image)
    }
    
    image.compressForUpload { (data, image) in
      
      self.printImageInfo(prefix: "DataSize", image: image)

      let image2 = image.imageScaledWithoutCliped(to: imageDefaultSize)!

      self.printImageInfo(prefix: "DataSize-size", image: image2)

    }
    
  }
  
  func printImageInfo(prefix: String, image: UIImage) {
    
    print("\(prefix),size: \(image.size), dataSize \(UIImageJPEGRepresentation(image, 1)!.count)")
  }
}

extension ViewController: ImagePickerDelegate {
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, images: [UIImage]) {
    
    print("count \(images.count)")

    for (index, image) in images.enumerated() {
      
      if index >= imageViews.count {
        return
      }
      
      imageViews[index].image = image
    }
    
  }
  
  func pickedPhoto(_ imagePickerHelper: ImagePickerHelper, didPickResource resource: ResourceType) {
    print(#function)
    if case .video(video: let tmpAVAsset) = resource, let avAsset = tmpAVAsset {
      print(avAsset)
    }
    
    if case .rawImageData(imageData: let imageData) = resource, let _imageData = imageData {
      
      print(_imageData.count)
    }
    
    if case .image(images: let images) = resource {
      print(images.count)
    }
  }
}


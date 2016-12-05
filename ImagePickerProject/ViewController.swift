//
//  ViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

let separatorColor = UIColor.hexStringToColor("e5e5e5")

class ViewController: UIViewController {

  @IBOutlet var isCropSwitch: UISwitch!
  @IBOutlet var maxCountTextField: UITextField!
  
  var imagePickerHelper: ImagePickerHelper!
  var isCrop: Bool = true
  var type: ImagePickerType = .albumAndCamera
  var maxCount = 3
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imagePickerHelper = ImagePickerHelper(delegate: self)
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func onStart() {
    
    imagePickerHelper.isCrop = isCrop
    imagePickerHelper.maxSelectedCount = maxCount
    imagePickerHelper.type = type
    imagePickerHelper.startPhoto()
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

    for image in images {
      testCompression(image: image)
    }
  }
}

import UIKit
extension UIImage {
  
  func imageScaledToSize(_ newSize:CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
  }
  
  func imageScaledWithoutCliped(to maxSize: CGSize) -> UIImage? {
    
    guard maxSize != CGSize.zero else { return nil }
    
    let widthScale = maxSize.width / self.size.width
    let heightScale = maxSize.height / self.size.height
    
    let targetScale = min(widthScale, heightScale)
    
    if widthScale > 1 && heightScale > 1 { return self }
    
    let displaySize = CGSize(width: ceil(self.size.width * targetScale), height: ceil(self.size.height * targetScale))
    
    return imageScaledToSize(displaySize)
  }
  
  func compressForUpload(_ completion: @escaping ((_ compressedImageData: Data, _ compressedImage: UIImage) -> Void)){
    
    exChangeGloableeQueue {
      
      let maxSize: Int = 1024 * 250
      var currentCompression: CGFloat = 1
      let compressionByStep: CGFloat = 0.5
      let maxCompressionNum = 20
      var currentCompressionNum = 0
      
      var imageData = UIImageJPEGRepresentation(self, 1)!
      
      while imageData.count > maxSize && maxCompressionNum > currentCompressionNum {
        
        currentCompressionNum += 1
        currentCompression *= compressionByStep
        imageData = UIImageJPEGRepresentation(self, currentCompression)!
        
      }
      
      let compressedImage = UIImage(data: imageData)!
      
      exChangeMainQueue({
        
        completion(imageData, compressedImage)
        
      })
    }
    
  }
}

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
  var type: ImagePickerType = .AlbumAndCamera
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
  
  @IBAction func onIsCrop(sender: UISwitch) {
    
    isCrop = sender.on
    
    if isCrop {
      maxCountTextField.text = "1"
      maxCount = 1
    }
    
  }
  
  @IBAction func onStyle(sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      type = .AlbumAndCamera
    case 1:
      type = .Album
    case 2:
      type = .Camera
    default:
      break
    }
  }
  
  @IBAction func onCountChange(sender: UITextField) {
    
    guard let maxCount = Int(sender.text!) else { return }
    
    self.maxCount = maxCount
    
    if maxCount != 1 {
      isCropSwitch.setOn(false, animated: true)
    }
  }
  

}

extension ViewController: ImagePickerDelegate {
  func pickedPhoto(imagePickerHelper: ImagePickerHelper, images: [UIImage]) {
    
    print("count \(images.count)")
//    image = images[0]
    
//    dealImage(image)
    
//    for (index, image) in images.enumerate() {
//      imageViewList[index].image = image
//    }
  }
}
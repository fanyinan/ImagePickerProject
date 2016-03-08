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

  var imagePickerHelper: ImagePickerHelper!
  @IBOutlet weak var imageView1: UIImageView!
  @IBOutlet weak var imageView2: UIImageView!
  @IBOutlet weak var imageView3: UIImageView!

  @IBOutlet weak var imageView4: UIImageView!
  @IBOutlet weak var imageView5: UIImageView!

  var imageViewList: [UIImageView] = []
  
  var value1: CGFloat = 1
  var value2: CGFloat = 1
  var image: UIImage!
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    imageViewList += [imageView1]
//    imageViewList += [imageView2]
//    imageViewList += [imageView3]

    
    imagePickerHelper = ImagePickerHelper(delegate: self)
//    imagePickerHelper.maxSelectedCount = 4
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func onStart() {
    
//    imagePickerHelper.isCrop = true
    imagePickerHelper.maxSelectedCount = 3
    imagePickerHelper.startPhoto()
  }

  func getOrientation(image: UIImage) -> String {
    
    var imageOrientation = ""
    
    switch image.imageOrientation {
    case .Down:
      imageOrientation = "Down"
    case .Up:
      imageOrientation = "Up"
    case .Left:
      imageOrientation = "Left"
    case .Right:
      imageOrientation = "Right"
    case .DownMirrored:
      imageOrientation = "DownMirrored"
    case .UpMirrored:
      imageOrientation = "UpMirrored"
    case .RightMirrored:
      imageOrientation = "RightMirrored"
    case .LeftMirrored:
      imageOrientation = "LeftMirrored"
    }
    
    return imageOrientation
  }
  
  @IBAction func changeValue1(sender: UISlider) {
    value1 = CGFloat(sender.value)
    
    reDraw()
  }
  
  @IBAction func changeValue2(sender: UISlider) {
    value2 = CGFloat(sender.value)
    reDraw()
  }
  
  /**
   旋转图片
   
   - parameter image: 原图
   
   - returns: 旋转后的图片
   */
  func fixOrientation(image: UIImage) -> UIImage {
    
    //    if image.imageOrientation == UIImageOrientation.Up {
    //      return image
    //    }
    var transform = CGAffineTransformIdentity
    typealias o = UIImageOrientation
    let width = image.size.width
    let height = image.size.height
    
    switch (image.imageOrientation) {
    case o.Down, o.DownMirrored:
      transform = CGAffineTransformTranslate(transform, width, height)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
    case o.Left, o.LeftMirrored:
      transform = CGAffineTransformTranslate(transform, width, 0)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
    case o.Right, o.RightMirrored:
      transform = CGAffineTransformTranslate(transform, 0, height)
      transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
    default: // o.Up, o.UpMirrored:
      break
    }
    
//    switch (image.imageOrientation) {
//    case o.UpMirrored, o.DownMirrored:
//      transform = CGAffineTransformTranslate(transform, width, 0)
//      transform = CGAffineTransformScale(transform, -1, 1)
//    case o.LeftMirrored, o.RightMirrored:
//      transform = CGAffineTransformTranslate(transform, height, 0)
//      transform = CGAffineTransformScale(transform, -1, 1)
//    default: // o.Up, o.Down, o.Left, o.Right
//      break
//    }
    let cgimage = image.CGImage
    
    let ctx = CGBitmapContextCreate(nil, Int(width), Int(height),
      CGImageGetBitsPerComponent(cgimage), 0,
      CGImageGetColorSpace(cgimage),
      CGImageGetBitmapInfo(cgimage).rawValue)
    
//    CGContextConcatCTM(ctx, transform)
    
//    switch (image.imageOrientation) {
//    case o.Left, o.LeftMirrored, o.Right, o.RightMirrored:
//      CGContextDrawImage(ctx, CGRectMake(0, 0, height, width), cgimage)
//    default:
      CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), cgimage)
//    }
    let cgimg = CGBitmapContextCreateImage(ctx)
    let img = UIImage(CGImage: cgimg!)
    return img
    
  }
  
  func dealImage(image: UIImage) {
    
    print("size : \(image.size), orientation: \(getOrientation(image))")
    
//    imageView4.layer.contentsRect = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
    imageView4.image = image
    
    print("----------------------------")
    
    let image2 = fixOrientation(image)
//    let image2 = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: .Up)

    print("size : \(image2.size), orientation: \(getOrientation(image2))")

    imageView5.layer.contentsRect = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
    imageView5.image = image2

  }
  
  func reDraw() {
    dealImage(image)
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
//
//  UIImage+extensions.swift
//  MuMu
//
//  Created by jtianling on 8/5/15.
//  Copyright © 2015 juxin. All rights reserved.
//

import Foundation
import UIKit
extension UIImage {
  
  func clipImage(withRectScale rectScale: CGRect) -> UIImage? {
    
    let clipedRect = CGRect(x: size.width * rectScale.minX, y: size.height * rectScale.minY, width: size.width * rectScale.width, height: size.height * rectScale.height)
    
    let orientationRect = transformOrientationRect(clipedRect)
    
    let cropImageRef = self.cgImage?.cropping(to: orientationRect)
    
    guard let _cropImageRef = cropImageRef else { return nil }
    
    let cropImage = UIImage(cgImage: _cropImageRef, scale: 1, orientation: imageOrientation)
    
    return cropImage
    
  }
  
  //旋转rect
  func transformOrientationRect(_ rect: CGRect) -> CGRect {
    
    var rectTransform: CGAffineTransform = CGAffineTransform.identity
    
    switch imageOrientation {
    case .left:
      rectTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2)).translatedBy(x: 0, y: -size.height)
    case .right:
      rectTransform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2)).translatedBy(x: -size.width, y: 0)
    case .down:
      rectTransform = CGAffineTransform(rotationAngle: CGFloat(-M_PI)).translatedBy(x: -size.width, y: -size.height)
    default:
      break
    }
    
    let orientationRect = rect.applying(rectTransform.scaledBy(x: scale, y: scale))
    
    return orientationRect
    
  }
  
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

//
//  PhotoCollectionCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/6/9.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit
import Photos

class PhotoCollectionLiteCell: UICollectionViewCell {
  
  var zoomImageScrollView: ZoomImageScrollViewLite!
  var padding: CGFloat = 0 {
    didSet{
      zoomImageScrollView.frame = CGRect(x: padding, y: 0, width: frame.width - padding * CGFloat(2), height: frame.height)
    }
  }
  
  var asset: PHAsset! {
    didSet{
      guard asset != nil else { return }
      updateImage()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    zoomImageScrollView = ZoomImageScrollViewLite()
    zoomImageScrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    contentView.addSubview(zoomImageScrollView)
    
    
  }
  
  func updateImage() {
    
    let currentTag = tag + 1
    tag = currentTag
    
    PhotosManager.sharedInstance.fetchImage(with: asset, sizeType: .preview, handleCompletion: { (image: UIImage?, isInICloud) -> Void in
      
      guard currentTag == self.tag else {
        
        return
      }
      
      self.zoomImageScrollView.setImage(image == nil ? UIImage(named: "default_pic") : image)
      
    })
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

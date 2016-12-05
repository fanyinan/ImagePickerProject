//
//  PhotoCollectionCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/6/9.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class PhotoCollectionLiteCell: UICollectionViewCell {

  var zoomImageScrollView: ZoomImageScrollViewLite!
  var padding: CGFloat = 0 {
    didSet{
      zoomImageScrollView.frame = CGRect(x: padding, y: 0, width: frame.width - padding * CGFloat(2), height: frame.height)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    zoomImageScrollView = ZoomImageScrollViewLite()
    zoomImageScrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    contentView.addSubview(zoomImageScrollView)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

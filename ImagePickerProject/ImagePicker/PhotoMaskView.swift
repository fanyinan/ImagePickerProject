//
//  PhotoMaskView.swift
//  Yuanfenba
//
//  Created by 范祎楠 on 15/12/21.
//  Copyright © 2015年 Juxin. All rights reserved.
//

import UIKit

class PhotoMaskView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor.clearColor()
    userInteractionEnabled = false
    
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func drawRect(rect: CGRect) {
    
    let ctx = UIGraphicsGetCurrentContext()
    
    CGContextSetFillColorWithColor(ctx, UIColor.hexStringToColor("000000", alpha: 0.5).CGColor)
    CGContextFillRect(ctx, rect);
    CGContextStrokePath(ctx);
    
    CGContextClearRect(ctx, CGRect(x: 0, y: (rect.height - rect.width) / 2, width: rect.width, height: rect.width))
    
    CGContextSetRGBStrokeColor(ctx, 1, 1.0, 1.0, 1.0)
    CGContextSetLineWidth(ctx, 1.0)
    CGContextAddRect(ctx, CGRect(x: 1, y: (rect.height - rect.width) / 2, width: rect.width - 2, height: rect.width));
    CGContextStrokePath(ctx)
  }
  
  
}

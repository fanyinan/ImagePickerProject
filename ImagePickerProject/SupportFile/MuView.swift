//
//  MuView.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/11.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

extension UIView {
 
  
  /**
  设置圆角
  
  - parameter radius: 圆角半径，为空时，按计算height/2计算，宽高相等时为圆形
  */
  func setViewCornerRadius(_ radius : CGFloat? = nil){
    
    var tmpRadius: CGFloat!
    
    if let _radius = radius {
      tmpRadius = _radius
    } else {
      tmpRadius = self.frame.size.height / 2
    }
    self.layer.cornerRadius = tmpRadius
    self.layer.masksToBounds = true
  }

}

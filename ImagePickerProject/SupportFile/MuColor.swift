//
//  MuColor.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/9.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit


extension UIColor {
  
  class var jx_main: UIColor { return UIColor(hex: 0x333333) }

  convenience init(hex: Int, alpha: CGFloat = 1) {
    
    let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat((hex & 0x0000FF)) / 255.0
    
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
  /**
  随机颜色
  
  - returns: 颜色
  */
  class func randomColor() -> UIColor{
    
    let hue = CGFloat(arc4random() % 256) / 256.0
    let saturation = CGFloat(arc4random() % 128) / 256.0 + 0.5
    let brightness : CGFloat = CGFloat(arc4random() % 128) / 256.0 + 0.5
    
    return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
  }
}

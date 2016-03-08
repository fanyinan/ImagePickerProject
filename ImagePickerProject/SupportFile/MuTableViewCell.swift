
//
//  MuTableViewCell.swift
//  MuMu
//
//  Created by 范祎楠 on 15/7/17.
//  Copyright © 2015年 juxin. All rights reserved.
//

import UIKit

extension UITableViewCell {
  
  //解决tableview的分割线无法顶到头
  func setSeparatorByEdge(){
    
    self.separatorInset = UIEdgeInsetsZero
    
    if self.respondsToSelector("setLayoutMargins:"){
      self.layoutMargins = UIEdgeInsetsZero
    }
    
  }
  
  func clearSeparator(){
    self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.bounds.size.width)

  }
}
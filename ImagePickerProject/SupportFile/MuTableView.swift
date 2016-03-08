//
//  UITableView.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/11.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

extension UITableView {
  
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
  /**
  取消选中状态
  */
  func deselectRow(){
    
    if let indexPath = self.indexPathForSelectedRow {
      self.deselectRowAtIndexPath(indexPath, animated: true)
    }
  }
  
  /**
  加载cell的xib文件
  
  - parameter identifier: 文件名
  */
  func setNibCell(nibName : String){
    
    let nibCell = UINib(nibName: nibName, bundle: nil)
    
    self.registerNib(nibCell, forCellReuseIdentifier: nibName)
  }
  
}

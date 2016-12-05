//
//  Utility.swift
//  Yuanfenba
//
//  Created by 范祎楠 on 16/7/4.
//  Copyright © 2016年 Juxin. All rights reserved.
//

import Foundation

func exChangeGloableeQueue(_ handle: @escaping ()->Void) {
  
  DispatchQueue.global().async {
    handle()
  }
}

func exChangeMainQueue(_ handle: @escaping ()->Void) {
  
  DispatchQueue.main.async {
    handle()
  }
}


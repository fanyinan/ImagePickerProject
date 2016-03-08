//
//  MuViewController.swift
//  MuMu
//
//  Created by 范祎楠 on 15/7/17.
//  Copyright © 2015年 juxin. All rights reserved.
//


extension UIViewController {
  
  //添加navigationbar的返回按钮
  func setNaviBackButton(title: String = "返回"){
    let backBarItem = UIBarButtonItem()
    backBarItem.title = title
    self.navigationItem.backBarButtonItem = backBarItem
  }
  
  //跳转webview
  func showWebview(url: String) {
    
    if url.isEmpty {
      return
    }
    
    let viewController = UIViewController()
    let webView = UIWebView(frame: viewController.view.frame)
    webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
    viewController.view.addSubview(webView)
    navigationController?.pushViewController(viewController, animated: true)
  }
  
}

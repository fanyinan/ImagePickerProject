//
//  PopViewManager.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/16.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

@objc protocol PopViewHelperDelegate: NSObjectProtocol {
  
  @objc optional func popViewHelper(_ popViewHelper: PopViewHelper, shouldShowPopView targetView: UIView)
  @objc optional func popViewHelper(_ popViewHelper: PopViewHelper, shouldHidePopView targetView: UIView)
  @objc optional func popViewHelper(_ popViewHelper: PopViewHelper, didShowPopView targetView: UIView)
  @objc optional func popViewHelper(_ popViewHelper: PopViewHelper, didHidePopView targetView: UIView)
  @objc optional func popViewHelper(_ popViewHelper: PopViewHelper, didClickMask mask: UIControl)
  
}

//弹出方向
enum ViewPopDirection{
  case none
  case above
  case below
  case belowToCenter
  case center
  case onlyShowFullScreen
  case fade
}

//动画表现
enum AnimationStyle{
  case normal
  case spring
}

enum MaskStatus {
  case hidden
  case transparent
  case normal
  case clickDisable
}

class PopViewManager {
  
  static let sharedInstance = PopViewManager()
  fileprivate init() {}
  
  fileprivate var popViewHelperDic = [Int: PopViewHelper]()
  
  subscript(hash: Int) -> PopViewHelper? {
    
    get{
      return popViewHelperDic[hash]
    }
    
    set(newValue){
      popViewHelperDic[hash] = newValue
    }
  }
}

class PopViewHelper: NSObject {
  
  fileprivate(set) var isPoping = false //是否正在动画中
  fileprivate(set) var mask : UIControl?
  fileprivate var spring: CGFloat = 1 //动画弹性
  fileprivate var initVelocity: CGFloat = 0 //动画初始速度
  fileprivate var currentFrame: CGRect!
  fileprivate(set) var isShow = false //是否正在显示
  fileprivate var targetViewShadowOpacity: Float = 0
  
  weak var delegate: PopViewHelperDelegate?
  
  //可定制参数
  weak var targetView: UIView!
  var strongTargetView: UIView!
  var superView: UIView
  var viewPopDirection: ViewPopDirection
  var showAnimateDuration: TimeInterval = 0.25 //动画持续时间
  var hideAnimateDuration: TimeInterval = 0.25 //动画持续时间
  var alpha:[CGFloat] = [1,1,1]
  var beginOrgin: CGPoint = CGPoint.zero //开始位置
  var showOrgin: CGPoint = CGPoint.zero //弹出后位置
  var endOrgin: CGPoint = CGPoint.zero //收回
  var maskStatus: MaskStatus //是否显示遮罩
  var hideDelay: Double = 0
  var isLockTargetView = false {
    didSet{
      if isLockTargetView {
        strongTargetView = targetView
      } else {
        strongTargetView = nil
      }
    }
  }
  
  var isAnimatedForShadow = false { //是否存在阴影
    didSet{
      targetViewShadowOpacity = targetView.layer.shadowOpacity
      targetView.layer.shadowOpacity = 0
    }
  }
  
  var animationStyle: AnimationStyle = .normal{
    didSet{
      switch self.animationStyle {
      case .normal:
        spring = 1
        initVelocity = 0
        showAnimateDuration = 0.5
        hideAnimateDuration = 0.5
      case .spring:
        spring = 0.7
        initVelocity = 0
        showAnimateDuration = 0.5
        hideAnimateDuration = 0.5
      }
    }
  }
  
  init(superView: UIView?, targetView : UIView, viewPopDirection: ViewPopDirection = .none, maskStatus : MaskStatus = .normal){
    self.targetView = targetView
    self.maskStatus = maskStatus
    self.superView = superView ?? UIApplication.shared.keyWindow!
    self.viewPopDirection = viewPopDirection
    
    super.init()
    
    initMask(maskStatus)
    
    self.targetView.isHidden = true
    
  }

  fileprivate func setPopViewDirection() {
    
    switch viewPopDirection{
      
    case .above:
      
      beginOrgin.x = 0
      //隐藏在上面
      beginOrgin.y = -targetView.frame.height
      
      showOrgin.x = 0
      showOrgin.y = 0
      
      endOrgin = beginOrgin
      
    case .below:
      
      beginOrgin.x = 0
      //隐藏在下面
      beginOrgin.y = superView.frame.maxY
      
      showOrgin.x = 0
      showOrgin.y = superView.frame.height - targetView.frame.height
      
      endOrgin = beginOrgin
      
    case .belowToCenter:
      
      beginOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      //隐藏在下面
      beginOrgin.y = superView.frame.maxY
      
      showOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      showOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
      endOrgin = beginOrgin
      
    case .center:
      
      beginOrgin.x = superView.frame.maxX
      beginOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
      showOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      showOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
      endOrgin.x = -superView.frame.width
      endOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
    case .onlyShowFullScreen:
      
      beginOrgin = CGPoint(x: 0, y: 0)
      showOrgin = beginOrgin
      endOrgin = beginOrgin
      
    case .fade:
      
      alpha = [0,1,0]
      beginOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      beginOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      showOrgin = beginOrgin
      endOrgin = beginOrgin
      
    case .none:
      break
    }
  }
  
  fileprivate func setupUI(){
    
    targetView.frame.origin = beginOrgin
    targetView.alpha = alpha[0]
  }
  
  //初始化遮罩
  fileprivate func initMask(_ maskStatus: MaskStatus){
    
    if maskStatus == .hidden {
      return
    }
    
    mask = UIControl(frame: superView.bounds)
    mask!.alpha = 0
    mask!.backgroundColor = maskStatus == .transparent ? UIColor.clear : UIColor.black
    mask!.addTarget(self, action: #selector(PopViewHelper.onClickMask), for: .touchUpInside)
    
    superView.addSubview(mask!)
    
  }
  
  func onClickMask() {
    
    if let _mask = mask {
      delegate?.popViewHelper?(self, didClickMask: _mask)
    }
    
    guard maskStatus != .clickDisable else { return }
    
    hidePopView()
    
  }
  
  //现实弹出窗口
  func showPopView(){
    
    //如果没有正在播放动画则显示
    if !isPoping {
      
      setPopViewDirection()
      
      setupUI()
      
      if let _mask = mask{
        superView.bringSubview(toFront: _mask)
      }
      
      superView.addSubview(targetView)
      superView.bringSubview(toFront: targetView)
      targetView.isHidden = false
      isShow = true
      isPoping = true
      
      if self.isAnimatedForShadow {
        self.targetView.layer.shadowOpacity = self.targetViewShadowOpacity
      }
      
      delegate?.popViewHelper?(self, shouldShowPopView: targetView)
      
      UIView.animate(
        withDuration: showAnimateDuration,
        delay: TimeInterval(0),
        usingSpringWithDamping: spring,
        initialSpringVelocity: initVelocity,
        options: UIViewAnimationOptions(),
        animations: {
          self.mask?.alpha = 0.3
          self.targetView.frame.origin = CGPoint(x: self.showOrgin.x, y: self.showOrgin.y)
          self.targetView.alpha = self.alpha[1]
          
        },
        completion: {
          finished in
          self.isPoping = false
          self.delegate?.popViewHelper?(self, didShowPopView: self.targetView)
      })
    }
    
  }
  
  //隐藏弹出窗口
  func hidePopView(){
    
    //如果没有正在播放动画则隐藏
    if !isPoping {
      
      isPoping = true
      
      delegate?.popViewHelper?(self, shouldHidePopView: targetView)
      
      if self.isAnimatedForShadow {
        self.targetView.layer.shadowOpacity = 0
      }
      
      UIView.animate(
        withDuration: hideAnimateDuration,
        delay: TimeInterval(hideDelay),
        usingSpringWithDamping: spring,
        initialSpringVelocity: initVelocity,
        options: UIViewAnimationOptions(),
        animations: {
          self.mask?.alpha = 0
          self.targetView.frame.origin = CGPoint(x: self.endOrgin.x, y: self.endOrgin.y)
          self.targetView.alpha = self.alpha[2]
          
        },
        completion: {
          finished in
          self.isPoping = false
          self.isShow = false
          self.delegate?.popViewHelper?(self, didHidePopView: self.targetView)
          self.targetView.isHidden = true
          self.targetView.removeFromSuperview()
      })
      
    }
  }
  
  deinit{
    mask?.removeFromSuperview()
    targetView?.removeFromSuperview()
  }
}


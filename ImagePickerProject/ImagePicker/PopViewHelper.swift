//
//  PopViewManager.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/16.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

@objc protocol PopViewHelperDelegate: NSObjectProtocol {
  
  optional func popViewHelper(popViewHelper: PopViewHelper, shouldShowPopView targetView: UIView)
  optional func popViewHelper(popViewHelper: PopViewHelper, shouldHidePopView targetView: UIView)
  optional func popViewHelper(popViewHelper: PopViewHelper, didShowPopView targetView: UIView)
  optional func popViewHelper(popViewHelper: PopViewHelper, didHidePopView targetView: UIView)
  optional func popViewHelper(popViewHelper: PopViewHelper, didClickMask mask: UIControl)
  
}

//弹出方向
enum ViewPopDirection{
  case None
  case Above
  case Below
  case BelowToCenter
  case Center
  case OnlyShowFullScreen
  case Fade
}

//动画表现
enum AnimationStyle{
  case Normal
  case Spring
}

enum MaskStatus {
  case Hidden
  case Transparent
  case Normal
  case ClickDisable
}

class PopViewManager {
  
  static let sharedInstance = PopViewManager()
  private init() {}
  
  private var popViewHelperDic = [Int: PopViewHelper]()
  
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
  
  private(set) var isPoping = false //是否正在动画中
  private(set) var mask : UIControl?
  private var spring: CGFloat = 1 //动画弹性
  private var initVelocity: CGFloat = 0 //动画初始速度
  private var currentFrame: CGRect!
  private(set) var isShow = false //是否正在显示
  private var targetViewShadowOpacity: Float = 0
  
  weak var delegate: PopViewHelperDelegate?
  
  //可定制参数
  weak var targetView: UIView!
  var strongTargetView: UIView!
  var superView: UIView
  var viewPopDirection: ViewPopDirection
  var showAnimateDuration: NSTimeInterval = 0.25 //动画持续时间
  var hideAnimateDuration: NSTimeInterval = 0.25 //动画持续时间
  var alpha:[CGFloat] = [1,1,1]
  var beginOrgin: CGPoint = CGPointZero //开始位置
  var showOrgin: CGPoint = CGPointZero //弹出后位置
  var endOrgin: CGPoint = CGPointZero //收回
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
  
  var animationStyle: AnimationStyle = .Normal{
    didSet{
      switch self.animationStyle {
      case .Normal:
        spring = 1
        initVelocity = 0
        showAnimateDuration = 0.5
        hideAnimateDuration = 0.5
      case .Spring:
        spring = 0.7
        initVelocity = 0
        showAnimateDuration = 0.5
        hideAnimateDuration = 0.5
      }
    }
  }
  
  init(superView: UIView?, targetView : UIView, viewPopDirection: ViewPopDirection = .None, maskStatus : MaskStatus = .Normal){
    self.targetView = targetView
    self.maskStatus = maskStatus
    self.superView = superView ?? UIApplication.sharedApplication().keyWindow!
    self.viewPopDirection = viewPopDirection
    
    super.init()
    
    initMask(maskStatus)
    
    self.targetView.hidden = true
    
  }

  private func setPopViewDirection() {
    
    switch viewPopDirection{
      
    case .Above:
      
      beginOrgin.x = 0
      //隐藏在上面
      beginOrgin.y = -CGRectGetHeight(targetView.frame)
      
      showOrgin.x = 0
      showOrgin.y = 0
      
      endOrgin = beginOrgin
      
    case .Below:
      
      beginOrgin.x = 0
      //隐藏在下面
      beginOrgin.y = CGRectGetMaxY(superView.frame)
      
      showOrgin.x = 0
      showOrgin.y = CGRectGetHeight(superView.frame) - CGRectGetHeight(targetView.frame)
      
      endOrgin = beginOrgin
      
    case .BelowToCenter:
      
      beginOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      //隐藏在下面
      beginOrgin.y = CGRectGetMaxY(superView.frame)
      
      showOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      showOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
      endOrgin = beginOrgin
      
    case .Center:
      
      beginOrgin.x = CGRectGetMaxX(superView.frame)
      beginOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
      showOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      showOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
      endOrgin.x = -CGRectGetWidth(superView.frame)
      endOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      
    case .OnlyShowFullScreen:
      
      beginOrgin = CGPoint(x: 0, y: 0)
      showOrgin = beginOrgin
      endOrgin = beginOrgin
      
    case .Fade:
      
      alpha = [0,1,0]
      beginOrgin.x = superView.frame.width/2 - targetView.frame.width/2
      beginOrgin.y = superView.frame.height/2 - targetView.frame.height/2
      showOrgin = beginOrgin
      endOrgin = beginOrgin
      
    case .None:
      break
    }
  }
  
  private func setupUI(){
    
    targetView.frame.origin = beginOrgin
    targetView.alpha = alpha[0]
  }
  
  //初始化遮罩
  private func initMask(maskStatus: MaskStatus){
    
    if maskStatus == .Hidden {
      return
    }
    
    mask = UIControl(frame: superView.bounds)
    mask!.alpha = 0
    mask!.backgroundColor = maskStatus == .Transparent ? UIColor.clearColor() : UIColor.blackColor()
    mask!.addTarget(self, action: #selector(PopViewHelper.onClickMask), forControlEvents: .TouchUpInside)
    
    superView.addSubview(mask!)
    
  }
  
  func onClickMask() {
    
    if let _mask = mask {
      delegate?.popViewHelper?(self, didClickMask: _mask)
    }
    
    guard maskStatus != .ClickDisable else { return }
    
    hidePopView()
    
  }
  
  //现实弹出窗口
  func showPopView(){
    
    //如果没有正在播放动画则显示
    if !isPoping {
      
      setPopViewDirection()
      
      setupUI()
      
      if let _mask = mask{
        superView.bringSubviewToFront(_mask)
      }
      
      superView.addSubview(targetView)
      superView.bringSubviewToFront(targetView)
      targetView.hidden = false
      isShow = true
      isPoping = true
      
      if self.isAnimatedForShadow {
        self.targetView.layer.shadowOpacity = self.targetViewShadowOpacity
      }
      
      delegate?.popViewHelper?(self, shouldShowPopView: targetView)
      
      UIView.animateWithDuration(
        showAnimateDuration,
        delay: NSTimeInterval(0),
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
      
      UIView.animateWithDuration(
        hideAnimateDuration,
        delay: NSTimeInterval(hideDelay),
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
          self.targetView.hidden = true
          self.targetView.removeFromSuperview()
      })
      
    }
  }
  
  deinit{
    mask?.removeFromSuperview()
    targetView?.removeFromSuperview()
  }
}


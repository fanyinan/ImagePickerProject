//
//  PhotoTransitionPopAnimation.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/11/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PhotoTransitionDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {

  weak var showVC: WZPhotoBrowserAnimatedTransition?
  
  init(showVC: WZPhotoBrowserAnimatedTransition) {
    self.showVC = showVC
    super.init()
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return 0.3
  }

  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
    let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! WZPhotoBrowser
    let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
    
    transitionContext.containerView()!.addSubview(toVC.view)
    transitionContext.containerView()!.sendSubviewToBack(toVC.view)
    
    let fromView = fromVC.view
    fromView.alpha = 1
    fromVC.setMainTableViewHiddenForAnimation(true)
    
    let imageSizeInFromVC = fromVC.getCurrentDisplayImageSize()
    let imageViewForAnimation = UIImageView(frame: CGRect(origin: CGPointZero, size: imageSizeInFromVC))
    imageViewForAnimation.center = fromView.center
    imageViewForAnimation.image = fromVC.getCurrentDisplayImage()
    imageViewForAnimation.contentMode = .ScaleAspectFill
    imageViewForAnimation.clipsToBounds = true
    transitionContext.containerView()?.addSubview(imageViewForAnimation)
    
    var finalFrame = showVC!.getImageViewFrameInParentViewWith(fromVC.selectCellIndex)
    finalFrame = CGRectOffset(finalFrame, 0, 64)
    UIView.animateWithDuration(transitionDuration(transitionContext), animations: { () -> Void in
      
      fromView.alpha = 0
      imageViewForAnimation.frame = finalFrame
      
      }) { _ in
        
        imageViewForAnimation.removeFromSuperview()
        transitionContext.completeTransition(true)

    }
    
  }
  
}

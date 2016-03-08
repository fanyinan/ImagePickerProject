//
//  CropImageScrollView.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/12/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class CropImageScrollView: UIScrollView {

  private var imageView: UIImageView!
  private var simpleTap: UITapGestureRecognizer!
  private var netImageSize: CGSize!
  private var originImage: UIImage
  
  private var maskHeight: CGFloat!
  
  var imageContainerView: UIView!
  var padding: CGFloat = 0
    
  init(frame: CGRect, image: UIImage){
    
    self.originImage = image
    
    super.init(frame: frame)
    
    maskHeight = (frame.height - frame.width) / 2
    
    configUI()
    setImage(image)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    moveFrameToCenter()
  }
  
  func setImage(image: UIImage?) {
    
    if image == nil {
      return
    }
    
    imageView.image = image
    
    //这里设置imageview的size为imagesize在当前缩放比例下的size
    imageView.frame = CGRect(x: 0, y: 0, width: image!.size.width * zoomScale, height: image!.size.height * zoomScale)
    
    imageContainerView.frame = CGRect(x: 0, y: 0,width: imageView.frame.size.width , height: imageView.frame.size.height + maskHeight * 2)
    
    imageView.center = CGPoint(x: CGRectGetWidth(imageContainerView.frame) / 2, y: CGRectGetHeight(imageContainerView.frame) / 2)
    
    contentSize = imageContainerView.frame.size
    
    calculateZoomScale()
  }
  
  /**
   图片点击事件
   
   :param: target target
   :param: action action
   */
  func addImageTarget(target: AnyObject, action: Selector) {
    simpleTap.addTarget(target, action: action)
  }
  
  func getSelectedRectScale() -> (xScale: CGFloat, yScale: CGFloat, sizeScalse: CGFloat){
    
    let pointXScale = contentOffset.x / imageContainerView.frame.width
    let pointYScale = contentOffset.y / (imageContainerView.frame.height - maskHeight * 2)
    let sizeScalse = frame.width / imageContainerView.frame.width
    
    return (pointXScale, pointYScale, sizeScalse)
    
  }
  
  private func configUI() {
    
    delegate = self
    backgroundColor = UIColor.blackColor()
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollViewDecelerationRateFast
    alwaysBounceVertical = true
    alwaysBounceHorizontal = true
    bounces = true
    
    //imageview
    imageView = UIImageView(frame: CGRectZero)
    imageView.backgroundColor = UIColor.blackColor()
    imageView.contentMode = .ScaleAspectFill
    imageView.userInteractionEnabled = true
    simpleTap = UITapGestureRecognizer()
    imageView.addGestureRecognizer(simpleTap)
    
    imageContainerView = UIView(frame: CGRectZero)
    imageContainerView.addSubview(imageView)
    
    addSubview(imageContainerView)
  }
  
  private func calculateZoomScale() {
    
    let boundsSize = bounds.size
    let imageSize = imageView.image!.size
    
    let scaleX = (boundsSize.width - padding * CGFloat(2)) / imageSize.width
    let scaleY = boundsSize.height / imageSize.height
    
    var minScale = min(scaleX, scaleY)
    
    //如果图片长宽都小于屏幕则不缩放
    if scaleX > 1.0 && scaleY > 1.0 {
      minScale = 1.0
    }
    
    let maxScale = CGFloat(3)
    
    maximumZoomScale = maxScale
    
    
    minimumZoomScale = minScale
    zoomScale = minimumZoomScale
    
    setNeedsLayout()
    
    //这句话需要放在初次缩放后面
    
    var adjustPositionY = (CGRectGetHeight(imageContainerView.frame) - CGRectGetHeight(frame)) / 2
    
    adjustPositionY = adjustPositionY > 0 ? adjustPositionY : 0
    
    contentOffset = CGPoint(x: 0, y: adjustPositionY)
    
  }
  
  private func moveFrameToCenter() {
    
    let boundsSize = bounds.size
    var frameToCenter = imageContainerView.frame
    
    if boundsSize.width > frameToCenter.size.width {
      frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / CGFloat(2)
    } else {
      frameToCenter.origin.x = 0
    }
    
    if boundsSize.height > frameToCenter.size.height {
      frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / CGFloat(2)
    } else {
      frameToCenter.origin.y = 0
    }
  
    if !CGRectEqualToRect(imageContainerView.frame, frameToCenter) {
      imageContainerView.frame = frameToCenter
    }
    
  }
  
  private func updateUI() {
    
    imageContainerView.frame = CGRect(x: imageContainerView.frame.origin.x, y: imageContainerView.frame.origin.y,width: imageContainerView.frame.size.width , height: (imageView.frame.size.height * zoomScale + maskHeight * 2))
    
    imageView.frame = CGRect(origin: CGPoint(x: 0, y: maskHeight / zoomScale), size: imageView.frame.size)
    
    contentSize = imageContainerView.frame.size
    
  }
  
}

extension CropImageScrollView: UIScrollViewDelegate {
  
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return imageContainerView
  }
  
  func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
    scrollEnabled = true
  }
  
  //主要是解决先缩小后再松手弹回来时不会执行moveFrameToCenter()的问题
  func scrollViewDidZoom(scrollView: UIScrollView) {

    updateUI()

    setNeedsLayout()
    layoutIfNeeded()
    
    
  }
}
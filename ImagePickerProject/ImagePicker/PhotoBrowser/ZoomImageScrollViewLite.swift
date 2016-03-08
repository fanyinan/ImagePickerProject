//
//  ZoomImageScrollViewLite.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/1.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class ZoomImageScrollViewLite: UIScrollView, HTableViewForLitePhotoCellDelegate {
  
  private var imageView: UIImageView!
  private var simpleTap: UITapGestureRecognizer!
  private var imageSize: CGSize!
  var reuseIdentifier: String

  var padding: CGFloat = 0
  
  init(reuseIdentifier: String){
    self.reuseIdentifier = reuseIdentifier
    super.init(frame: CGRectZero)
    configUI()
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.reuseIdentifier = ""
    super.init(coder: aDecoder)
  }
  
  private func configUI() {
    backgroundColor = UIColor.blackColor()
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollViewDecelerationRateFast
    //    autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    alwaysBounceHorizontal = false
    delegate = self
    scrollEnabled = false //使图片开始是不能滑动的，因为当图片宽为600左右，scale为0.533左右时，htable无法滑动，具体原因不明
    
    //imageview
    imageView = UIImageView(frame: CGRectZero)
    imageView.backgroundColor = UIColor.blackColor()
    imageView.contentMode = .ScaleAspectFill
    imageView.userInteractionEnabled = true
    simpleTap = UITapGestureRecognizer()
    imageView.addGestureRecognizer(simpleTap)
    
    addSubview(imageView)
    
  }
  
  func setImage(image: UIImage?) {
    
    if image == nil {
      return
    }
    
    imageView.image = image
    //这里设置imageview的size为imagesize在当前缩放比例下的size
    imageView.frame = CGRect(x: 0, y: 0, width: image!.size.width * zoomScale, height: image!.size.height * zoomScale)
    contentSize = imageView.frame.size
    
    calculateZoomScale()
  }
  
  func setImageWithLocalPhotoWith(index: Int) {
        
    let currentTag = tag + 1
    tag = currentTag
    
    PhotosManager.sharedInstance.getImageInCurrentAlbumWith(index, withSizeType: .Preview) { (image) -> Void in
      
      guard image != nil else {
        return
      }
      
      guard currentTag == self.tag else {

        return
      }
      self.imageSize = image!.size
      self.setImage(image)
    }
  }
  
  /**
   图片点击事件
   
   :param: target target
   :param: action action
   */
  func addImageTarget(target: AnyObject, action: Selector) {
    simpleTap.addTarget(target, action: action)
  }
  
  private func calculateZoomScale() {
    
    let boundsSize = bounds.size
    
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
  }
  
  private func moveFrameToCenter() {
    
    let boundsSize = bounds.size
    var frameToCenter = imageView.frame
    
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
    
    if !CGRectEqualToRect(imageView.frame, frameToCenter) {
      imageView.frame = frameToCenter
    }
    
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    moveFrameToCenter()
  }
  
}

extension ZoomImageScrollViewLite: UIScrollViewDelegate {
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
    scrollEnabled = true
  }
  
  //主要是解决先缩小后再松手弹回来时不会执行moveFrameToCenter()的问题
  func scrollViewDidZoom(scrollView: UIScrollView) {
    setNeedsLayout()
    layoutIfNeeded()
  }
}
//
//  WZPhotoBrowser.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/2.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

protocol WZPhotoBrowserAnimatedTransition: NSObjectProtocol {
  
  //如果index为nil则返回当前点击的即将跳转图片浏器的图片的frame
  func getImageViewFrameInParentViewWith(index: Int?) -> CGRect
  
  func getImageForAnimation() -> UIImage?
  
}

@objc protocol WZPhotoBrowserDelegate: NSObjectProtocol {
  
  func numberOfImage(photoBrowser: WZPhotoBrowser) -> Int
  
  //如果不实现则访问本地相册
  optional func displayImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> String
  
  optional func placeHolderImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> UIImage?
  optional func firstDisplayIndex(photoBrowser: WZPhotoBrowser) -> Int
  optional func photoBrowser(photoBrowser: WZPhotoBrowser, didSelectImageAtIndex: Int)
  
}

class WZPhotoBrowser: UIViewController {
  
  private var mainTableView: HTableViewForPhoto!
  private var thumbTableView: HTableView!
  private var borderView: UIImageView!
  
  private var thumbWidth: CGFloat!
  private var isDraggingMainView = true
  private var isMoveThumb = false //当图片数量少于thumbNum时，thumbTableview不会移动
  private var isClickThumb = false
  private var isNetImage = false
  
  var delegate: WZPhotoBrowserDelegate
  var quitBlock: (() -> Void)?
  var selectCellIndex: Int = 0 {
    didSet{
      photoDidChange()
    }
  }
  var isAnimate = false //用于设置是否经过动画跳转来 ，由PhotoTransitionPushAnimation设置
  var isDidShow = false //用于标记次VC是否已经呈现
  var isShowThumb = false
  //主图中每移动一张照片，缩略图需要移动的距离
  var distancePerMainPhoto: CGFloat!
  
  let IDENTIFIER_IMAGE_CELL = "ZoomImageCell"
  let IDENTIFIER_THUMB_CELL = "ThumbCell"
  let thumbNum: Float = 5.5
  let padding: CGFloat = 6
  let borderWidth: CGFloat = 4
  let cleardeviation: CGFloat = 0
  let contentOffsetDuration: NSTimeInterval = 0.3
  
  init(delegate: WZPhotoBrowserDelegate, quitBlock: (() -> Void)? = nil) {
    
    self.delegate = delegate
    self.quitBlock = quitBlock
    super.init(nibName: nil, bundle: nil)
    
    if delegate.respondsToSelector("displayImageWithIndex:index:") {
      isNetImage = true
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    initView()
    
    isMoveThumb = delegate.numberOfImage(self) > Int(thumbNum)

    distancePerMainPhoto = (thumbTableView.contentSize.width - thumbTableView.frame.width) / CGFloat(delegate.numberOfImage(self) - 1)
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    mainTableView.moveToPage(delegate.firstDisplayIndex?(self) ?? 0)
    
    //当默认显示第0张时，selectCellIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if delegate.firstDisplayIndex?(self) != nil && (delegate.firstDisplayIndex?(self))! == 0 {
      selectCellIndex = 0
    }

    hideNavigationBar()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  private func initView() {
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.blackColor()
    view.clipsToBounds = true
    
    initMainTableView()
    
    initThumbTableView()
    
    initBoardView()
    
  }
  
  private func initMainTableView() {
    
    mainTableView = HTableViewForPhoto(frame: CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height))
    mainTableView.delegateForHTableView = self
    mainTableView.dataSource = self
    mainTableView.pagingEnabled = true
    mainTableView.backgroundColor = UIColor.blackColor()
    view.addSubview(mainTableView)
    
  }
  
  private func initThumbTableView() {
    
    thumbWidth = view.frame.width / CGFloat(thumbNum)
    thumbTableView = HTableView(frame: CGRect(x: 0, y: mainTableView.bounds.height - thumbWidth, width: view.bounds.width, height: thumbWidth))
    thumbTableView.hidden = !isShowThumb
    thumbTableView.decelerationRate = 0
    thumbTableView.delegateForHTableView = self
    thumbTableView.dataSource = self
    thumbTableView.backgroundColor = UIColor.hexStringToColor("000000", alpha: 0.5)
    thumbTableView.pagingEnabled = false
    view.addSubview(thumbTableView)
  }
  
  private func initBoardView() {
    
    borderView = UIImageView(frame: CGRect(x: borderWidth / 2 - cleardeviation, y: thumbTableView.frame.minY , width: thumbWidth - borderWidth + cleardeviation * 2, height: thumbWidth))
    borderView.hidden = !isShowThumb
    borderView.image = UIImage(named: "img_kung")
    borderView.userInteractionEnabled = false
    view.addSubview(borderView)
  }
  
  /**
   收起navigationbar 暂不用
   */
  private func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    let isHidden = navigationController!.navigationBarHidden
    UIApplication.sharedApplication().setStatusBarHidden(!isHidden, withAnimation: .None)
    navigationController!.setNavigationBarHidden(!isHidden, animated: true)
    
  }
  
  //调整缩略图的偏移
  private func adjustThumOffset(offsetX: CGFloat) {
    
    //通过四舍五入计算需要移动到哪一个照片的位置
    let finalIndex = lroundf(Float(offsetX / distancePerMainPhoto))
    
    UIView.animateWithDuration(contentOffsetDuration, animations: { () -> Void in
      
      self.thumbTableView.setContentOffset(CGPoint(x: CGFloat(finalIndex) * self.distancePerMainPhoto, y: 0), animated: false)
      
      }) { (finish) -> Void in
        
        //校正零点几像素的偏差
        //        self.moveBorderViewTo(finalIndex)
        
    }
    
    
  }
  
  private func moveBorderView(progress: CGFloat) {
    //当图片数量少于thumbNum时，borderView不会滑到头
    let rangeWidth = isMoveThumb == true ? view.frame.width : thumbTableView.contentSize.width
    let borderViewOffset = progress * (rangeWidth - borderWidth - borderView.frame.width) - cleardeviation
    
    borderView.frame = CGRect(x: borderViewOffset + borderWidth / 2, y: borderView.frame.minY, width: borderView.frame.width, height: borderView.frame.height)
  }
  
  //直接移动边框到某位置
  private func moveBorderViewTo(didSelectRowAtIndex: Int) {
    
    let cell = thumbTableView.cellForRowAtIndex(didSelectRowAtIndex)
    var cellPointInView = view.convertPoint(cell.frame.origin, fromView: thumbTableView)
    cellPointInView.x += borderWidth / 2
    
    UIView.animateWithDuration(contentOffsetDuration, animations: { () -> Void in
      
      self.borderView.frame.origin = CGPoint(x: cellPointInView.x, y: self.borderView.frame.origin.y)
      
      }) { (finish) -> Void in
        
    }
  }
  
  func onClickPhoto() {
    
    quitBlock?()
    
  }
  
  func photoDidChange() {
      print("pb \(selectCellIndex)")

  }
  
  //for transitionAnimation
  func getCurrentDisplayImageSize() -> CGSize {
    
    let cell = mainTableView.cellForRowAtIndex(selectCellIndex)
    return cell.getImageSize()
  }
  
  //for transitionAnimation
  func setMainTableViewHiddenForAnimation(isHidden: Bool) {
    mainTableView.hidden = isHidden
  }
  
  //for transitionAnimation dismiss
  func getCurrentDisplayImage() -> UIImage? {
    
    let cell = mainTableView.cellForRowAtIndex(selectCellIndex)
    return cell.getImage()
  }

  //for transitionAnimation presnet
  func completePresent() {
    
    if isAnimate {
      
      isDidShow = true
      let cell = mainTableView.cellForRowAtIndex(selectCellIndex)
      
      if isNetImage {
        
        cell.setImageUrl(delegate.displayImageWithIndex!(self, index: selectCellIndex), placeholderImage: delegate.placeHolderImageWithIndex?(self, index: selectCellIndex), loadNow: true)

      }
    }
  }
}

extension WZPhotoBrowser: HTableViewForPhotoDataSource {
  
  func numberOfColumnsForPhoto(hTableView: HTableViewForPhoto) -> Int{
    return delegate.numberOfImage(self)
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, cellForColumnAtIndex index: Int) -> ZoomImageScrollView{
    var cell = hTableView.dequeueReusableCellWithIdentifier(IDENTIFIER_IMAGE_CELL)
    if cell == nil {
      cell = ZoomImageScrollView(reuseIdentifier: IDENTIFIER_IMAGE_CELL)
      cell!.addImageTarget(self, action: Selector("onClickPhoto"))
    }
    
    cell!.frame = mainTableView.frame
    cell!.padding = padding
    
    let loadNow = !(isAnimate && !isDidShow && selectCellIndex == index)
    
    if isNetImage {
      
      cell!.setImageUrl(delegate.displayImageWithIndex!(self, index: index), placeholderImage: delegate.placeHolderImageWithIndex?(self, index: index), loadNow: loadNow)

    } else {
      cell!.setImageWithLocalPhotoWith(index)
    }
    return cell!
  }
}

extension WZPhotoBrowser: HTableViewDataSource {
  
  func numberOfColumns(hTableView: HTableView) -> Int{
    return delegate.numberOfImage(self)
  }
  
  func hTableView(hTableView: HTableView, cellForColumnAtIndex index: Int) -> UITableViewCell{
    var cell = hTableView.dequeueReusableCellWithIdentifier() as? ThumbCell
    if cell == nil {
      cell = NSBundle.mainBundle().loadNibNamed(IDENTIFIER_THUMB_CELL, owner: self, options: nil).last as? ThumbCell
      cell!.setBorderWidth(borderWidth / 2)
    }
    
    let image = delegate.placeHolderImageWithIndex?(self, index: index)
    let imageUrl = delegate.displayImageWithIndex?(self, index: index)
    
    guard imageUrl != nil else {
      return cell!
    }
    if image != nil {
      cell!.setImageWith(image: image!)
    } else {
      
      cell!.setImageWith(imgUrl: imageUrl!)
      
    }
    
    return cell!
  }
}

extension WZPhotoBrowser: HTableViewForPhotoDelegate {
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, widthForColumnAtIndex index: Int) -> CGFloat{
    return mainTableView.frame.width
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, didSelectRowAtIndex: Int) {
    
    if delegate.photoBrowser == nil {
      onClickPhoto()
      return
    }
    
    delegate.photoBrowser!(self, didSelectImageAtIndex: didSelectRowAtIndex)
    
  }
  
  func hTableViewForPhotoDidScroll(hTableViewForPhoto: HTableViewForPhoto) {
    
    //更新selectCellIndex
    let cellPoint = view.convertPoint(hTableViewForPhoto.center, toView: mainTableView)
    let showPhotoIndex = mainTableView.indexForRowAtPoint(cellPoint)
    
    guard showPhotoIndex != nil else {
      return
    }
    
    if selectCellIndex != showPhotoIndex! {
      selectCellIndex = showPhotoIndex!
    }

    //只有当拖拽主图时才，缩略图才会移动，不然拖动缩略图时主图移动，又回使缩略图一起移动
    if !isDraggingMainView {
      return
    }
    
    var progress = hTableViewForPhoto.contentOffset.x / (hTableViewForPhoto.contentSize.width / CGFloat(delegate.numberOfImage(self)) * CGFloat(delegate.numberOfImage(self) - 1))
    
    progress = progress > 1.0 ? 1.0 : progress
    progress = progress < 0.0 ? 0.0 : progress
    
    moveBorderView(progress)
    
    if isMoveThumb {
      
      let thumbOffset = progress * (thumbTableView.contentSize.width - view.frame.width)
      thumbTableView.setContentOffset(CGPoint(x: thumbOffset, y: 0), animated: false)
      
    }
  }
  
  func hTableViewForPhotoWillBeginDragging(hTableViewForPhoto: HTableViewForPhoto) {
    
    isDraggingMainView = true
    isClickThumb = false
    
  }
  
  func hTableViewForPhotoDidEndDecelerating(hTableViewForPhoto: HTableViewForPhoto) {
    
//    let cellPoint = view.convertPoint(hTableViewForPhoto.center, toView: mainTableView)
//    let showPhotoIndex = mainTableView.indexForRowAtPoint(cellPoint)
//    selectCellIndex = showPhotoIndex ?? 0
    
    //校正零点几像素的偏差
    //    moveBorderViewTo(selectCellIndex)
    
  }
}



extension WZPhotoBrowser: HTableViewDelegate {
  func hTableView(hTableView: HTableView, widthForColumnAtIndex index: Int) -> CGFloat {
    return (thumbWidth)
  }
  
  func hTableViewWillBeginDragging(hTableView: HTableView) {
    
    hTableView.setContentOffset(CGPoint(x: hTableView.contentOffset.x + 1, y: 0), animated: false)
    
    isDraggingMainView = false
    isClickThumb = false
    
  }
  
  func hTableView(hTableView: HTableView, didSelectRowAtIndex: Int) {
    
    isClickThumb = true
    
    //防止滑动maintableview时thunmTableView 一起动
    isDraggingMainView = false
    
    mainTableView.moveToPage(didSelectRowAtIndex)
    
    selectCellIndex = didSelectRowAtIndex
    
    isDraggingMainView = true
    
    if isMoveThumb {
      
      self.thumbTableView.setContentOffset(CGPoint(x: self.distancePerMainPhoto * CGFloat(self.selectCellIndex), y: 0), animated: true)
      
    } else {
      
      moveBorderViewTo(didSelectRowAtIndex)
      
    }
    
  }
  
  func hTableViewDidScroll(hTableView: HTableView) {
    
    var progress = hTableView.contentOffset.x / (thumbTableView.contentSize.width - view.frame.width)
    
    progress = progress > 1.0 ? 1.0 : progress
    progress = progress < 0.0 ? 0.0 : progress
    
    //边框随缩略图移动
    
    if (isMoveThumb && !isDraggingMainView) || isClickThumb {
      
      moveBorderView(progress)
      
    }
    
    if isDraggingMainView {
      return
    }
    
    let mainPhotoShouldOffset = progress * (mainTableView.contentSize.width / CGFloat(delegate.numberOfImage(self)) * CGFloat(delegate.numberOfImage(self) - 1))
    
    //当移动了半张图片的距离是就显示下张图片
    if abs(mainPhotoShouldOffset - mainTableView.contentOffset.x) > mainTableView.frame.width / 2 {
      
      let offset = mainPhotoShouldOffset > mainTableView.contentOffset.x ? mainTableView.frame.width : -mainTableView.frame.width
      mainTableView.setContentOffset(CGPoint(x: mainTableView.contentOffset.x + offset, y: 0), animated: false)
      
    }
    
  }
  
  func hTableViewDidEndDecelerating(hTableView: HTableView) {
    
    let offsetX = hTableView.contentOffset.x
    adjustThumOffset(offsetX)
    
  }
  
  func hTableViewDidEndDragging(hTableView: HTableView, willDecelerate decelerate: Bool) {
    
    if decelerate {
      return
    }
    
    let offsetX = hTableView.contentOffset.x
    adjustThumOffset(offsetX)
  }
  
}

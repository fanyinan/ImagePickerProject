//
//  WZPhotoBrowserLite.swift
//  WZPhotoBrowserLite
//
//  Created by 范祎楠 on 15/9/2.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

protocol WZPhotoBrowserLiteDelegate: NSObjectProtocol {
  
  func numberOfImage(photoBrowser: WZPhotoBrowserLite) -> Int
  
  func firstDisplayIndex(photoBrowser: WZPhotoBrowserLite) -> Int
  
}

class WZPhotoBrowserLite: UIViewController {
  
  private var mainTableView: HTableViewForLitePhoto!
  
  var delegate: WZPhotoBrowserLiteDelegate
  var quitBlock: (() -> Void)?
  var selectCellIndex: Int = 0 {
    didSet{
      photoDidChange()
    }
  }
  
  var isDidShow = false //用于标记次VC是否已经呈现
  
  let IDENTIFIER_IMAGE_CELL = "ZoomImageCell"
  let padding: CGFloat = 6
  
  init(delegate: WZPhotoBrowserLiteDelegate, quitBlock: (() -> Void)? = nil) {
    
    self.delegate = delegate
    self.quitBlock = quitBlock
    super.init(nibName: nil, bundle: nil)

  }
  
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    initView()
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    mainTableView.moveToPage(delegate.firstDisplayIndex(self) ?? 0)
    
    //当默认显示第0张时，selectCellIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if (delegate.firstDisplayIndex(self)) == 0 {
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
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  private func initView() {
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.blackColor()
    view.clipsToBounds = true
    
    initMainTableView()
    
  }
  
  private func initMainTableView() {
    
    mainTableView = HTableViewForLitePhoto(frame: CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height))
    mainTableView.delegateForHTableView = self
    mainTableView.dataSource = self
    mainTableView.pagingEnabled = true
    mainTableView.backgroundColor = UIColor.blackColor()
    view.addSubview(mainTableView)
    
  }
  
  /**
   收起navigationbar 暂不用
   */
  private func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    let isHidden = navigationController!.navigationBarHidden
    navigationController!.setNavigationBarHidden(!isHidden, animated: true)
    
  }
  
  func onClickPhoto() {
    
    quitBlock?()
    
  }
  
  func photoDidChange() {
      print("pb \(selectCellIndex)")

  }
}

extension WZPhotoBrowserLite: HTableViewForLitePhotoDataSource {
  
  func numberOfColumnsForPhoto(hTableView: HTableViewForLitePhoto) -> Int{
    return delegate.numberOfImage(self)
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForLitePhoto, cellForColumnAtIndex index: Int) -> ZoomImageScrollViewLite{
    var cell = hTableView.dequeueReusableCellWithIdentifier(IDENTIFIER_IMAGE_CELL)
    if cell == nil {
      cell = ZoomImageScrollViewLite(reuseIdentifier: IDENTIFIER_IMAGE_CELL)
      cell!.addImageTarget(self, action: Selector("onClickPhoto"))
    }
    
    cell!.frame = mainTableView.frame
    cell!.padding = padding
    
    cell!.setImageWithLocalPhotoWith(index)

    return cell!
  }
}

extension WZPhotoBrowserLite: HTableViewForLitePhotoDelegate {
  
  func hTableViewForPhoto(hTableView: HTableViewForLitePhoto, widthForColumnAtIndex index: Int) -> CGFloat{
    return mainTableView.frame.width
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForLitePhoto, didSelectRowAtIndex: Int) {
    
    onClickPhoto()
    
  }
  
  func hTableViewForPhotoDidScroll(hTableViewForPhoto: HTableViewForLitePhoto) {
    
    //更新selectCellIndex
    let cellPoint = view.convertPoint(hTableViewForPhoto.center, toView: mainTableView)
    let showPhotoIndex = mainTableView.indexForRowAtPoint(cellPoint)
    
    guard showPhotoIndex != nil else {
      return
    }
    
    if selectCellIndex != showPhotoIndex! {
      selectCellIndex = showPhotoIndex!
    }

  }

}

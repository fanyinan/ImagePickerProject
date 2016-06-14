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
  
  private var mainCollectionView: UICollectionView!
  
  weak var delegate: WZPhotoBrowserLiteDelegate?
  var quitBlock: (() -> Void)?
  var currentIndex: Int = 0 {
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
    
    let photoIndex = delegate?.firstDisplayIndex(self) ?? 0
    mainCollectionView.setContentOffset(CGPoint(x: CGFloat(photoIndex) * CGRectGetWidth(mainCollectionView.frame), y: 0), animated: false)
    
    //当默认显示第0张时，currentIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if delegate?.firstDisplayIndex(self) != nil && (delegate?.firstDisplayIndex(self))! == 0 {
      currentIndex = 0
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
    
    let mainCollectionViewFrame = CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height)
    
    let mainCollectionViewLayout = UICollectionViewFlowLayout()
    mainCollectionViewLayout.itemSize = mainCollectionViewFrame.size
    mainCollectionViewLayout.minimumInteritemSpacing = 0
    mainCollectionViewLayout.minimumLineSpacing = 0
    mainCollectionViewLayout.scrollDirection = .Horizontal
    
    mainCollectionView = UICollectionView(frame: mainCollectionViewFrame, collectionViewLayout: mainCollectionViewLayout)
    mainCollectionView.delegate = self
    mainCollectionView.dataSource = self
    mainCollectionView.pagingEnabled = true
    mainCollectionView.backgroundColor = UIColor.blackColor()
    mainCollectionView.registerClass(PhotoCollectionLiteCell.self, forCellWithReuseIdentifier: "PhotoCollectionLiteCell")
    view.addSubview(mainCollectionView)
    
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

  }
}

extension WZPhotoBrowserLite: UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate?.numberOfImage(self) ?? 0
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionLiteCell", forIndexPath: indexPath) as! PhotoCollectionLiteCell
    
    cell.zoomImageScrollView.addImageTarget(self, action: #selector(WZPhotoBrowserLite.onClickPhoto))
    
    cell.padding = padding
    
    cell.zoomImageScrollView.setImageWithLocalPhotoWith(indexPath.row)
    
    return cell
    
  }
}

extension WZPhotoBrowserLite: UICollectionViewDelegateFlowLayout {
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    
    //更新currentIndex
    let cellPoint = view.convertPoint(mainCollectionView.center, toView: mainCollectionView)
    let showPhotoIndex = mainCollectionView.indexPathForItemAtPoint(cellPoint)
    
    if let _showPhotoIndex = showPhotoIndex where currentIndex != _showPhotoIndex {
      currentIndex = showPhotoIndex!.row
    }
    
  }
  
}

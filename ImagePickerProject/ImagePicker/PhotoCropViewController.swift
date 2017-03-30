//
//  PhotoCropViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/12/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PhotoCropViewController: UIViewController {
  
  var imageIndex: Int?
  
  var originImage: UIImage!
  
  var cropImageScrollView: CropImageScrollView!
  
  var bottomBarContainerView: UIView!
  var bottomBarTransparentView: UIView!
  var completeButton: UIButton!
  var cancelButton: UIButton!
  
  var imageView: UIImageView!
  
  init(imageIndex: Int) {
    
    self.imageIndex = imageIndex
    
    super.init(nibName: nil, bundle: nil)
  }
  
  init(image: UIImage) {
    
    self.originImage = image
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.black
    
    guard originImage == nil else {
      self.setupUI()
      return
    }
    
    PhotosManager.sharedInstance.getImageInCurrentAlbumWith(imageIndex!, withSizeType: .preview, handleCompletion: { (image: UIImage?, _) -> Void in
      
      guard let _image = image else {
        return
      }
      
      self.originImage = _image
      self.setupUI()
      
    }, handleImageRequestID: nil)
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    hideNavigationBar()
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /******************************************************************************
   *  Target-Action
   ******************************************************************************/
  //MARK: - Target-Action
  
  func onComplete() {
    
    let (xScale, yScale, sizeScalse) = cropImageScrollView.getSelectedRectScale()
    
    PhotosManager.sharedInstance.rectScale = ImageRectScale(xScale: xScale, yScale: yScale, widthScale: sizeScalse, heighScale: sizeScalse)
    
    if imageIndex != nil {
      PhotosManager.sharedInstance.selectPhotoWith(imageIndex!)
    } else {
      //如果用相机拍摄的照片需要直接裁剪
      originImage = PhotosManager.sharedInstance.cropImage(originImage)
    }
    
    PhotosManager.sharedInstance.didFinish(imageIndex == nil ? originImage : nil)
    
  }
  
  func onCancel() {
    
    if navigationController == nil {
      self.dismiss(animated: true, completion: nil)
    } else {
      navigationController!.popViewController(animated: true)
    }
    
  }
  
  /******************************************************************************
   *  Private Method Implementation
   ******************************************************************************/
  //MARK: - Private Method Implementation
  
  /**
   收起navigationbar 暂不用
   */
  fileprivate func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    let isHidden = navigationController!.isNavigationBarHidden
    UIApplication.shared.setStatusBarHidden(!isHidden, with: .none)
    navigationController!.setNavigationBarHidden(!isHidden, animated: true)
    
  }
  
  fileprivate func setupUI() {
    
    automaticallyAdjustsScrollViewInsets = false
    
    cropImageScrollView = CropImageScrollView(frame: view.bounds, image: originImage)
    view.addSubview(cropImageScrollView)
    
    let maskView = PhotoMaskView(frame: view.bounds)
    view.addSubview(maskView)
    
    initBottomBar()
    
  }
  
  fileprivate func initBottomBar() {
    
    //bottomBarTransparentView
    bottomBarTransparentView = UIView()
    view.addSubview(bottomBarTransparentView)
    bottomBarTransparentView.snp.makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(60)
    }
    
    bottomBarTransparentView.alpha = 0.7
    bottomBarTransparentView.backgroundColor = UIColor.hexStringToColor("111111")
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(60)
    }
    
    bottomBarContainerView.backgroundColor = UIColor.clear
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp.makeConstraints { (make) -> Void in
      make.right.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(60)
    }
    
    completeButton.setTitle("选取", for: UIControlState())
    completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    completeButton.setTitleColor(UIColor.white, for: UIControlState())
    completeButton.addTarget(self, action: #selector(PhotoCropViewController.onComplete), for: .touchUpInside)
    
    //selectedCountLabel
    cancelButton = UIButton()
    bottomBarContainerView.addSubview(cancelButton)
    cancelButton.snp.makeConstraints { (make) -> Void in
      make.left.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(60)
    }
    
    cancelButton.setTitle("取消", for: UIControlState())
    cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    cancelButton.setTitleColor(UIColor.white, for: UIControlState())
    cancelButton.addTarget(self, action: #selector(PhotoCropViewController.onCancel), for: .touchUpInside)
    
    imageView = UIImageView()
    view.addSubview(imageView)
    imageView.snp.makeConstraints { (make) -> Void in
      make.centerX.equalTo(view)
      make.bottom.equalTo(view)
      make.width.height.equalTo(140)
    }
  }
  
}

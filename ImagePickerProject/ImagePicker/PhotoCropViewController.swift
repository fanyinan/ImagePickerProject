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
    
    guard originImage == nil else {
      self.initView()
      return
    }
    
    PhotosManager.sharedInstance.getImageInCurrentAlbumWith(imageIndex!, withSizeType: .Preview) { (image) -> Void in
      
      guard let _image = image else {
        return
      }
      
      self.originImage = _image
      self.initView()

    }

  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    hideNavigationBar()
    
  }
  
  override func viewWillDisappear(animated: Bool) {
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
    
    PhotosManager.sharedInstance.clearData()

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
    
    navigationController?.popViewControllerAnimated(true)

  }
  
  /******************************************************************************
   *  Private Method Implementation
   ******************************************************************************/
   //MARK: - Private Method Implementation
   
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

  private func initView() {
    
    automaticallyAdjustsScrollViewInsets = false

    cropImageScrollView = CropImageScrollView(frame: view.bounds, image: originImage)
    view.addSubview(cropImageScrollView)
    
    let maskView = PhotoMaskView(frame: view.bounds)
    view.addSubview(maskView)

    initBottomBar()
    
  }
  
  private func initBottomBar() {
    
    //bottomBarTransparentView
    bottomBarTransparentView = UIView()
    view.addSubview(bottomBarTransparentView)
    bottomBarTransparentView.snp_makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(60)
    }
    
    bottomBarTransparentView.alpha = 0.7
    bottomBarTransparentView.backgroundColor = UIColor.hexStringToColor("111111")
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp_makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(60)
    }
    
    bottomBarContainerView.backgroundColor = UIColor.clearColor()
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp_makeConstraints { (make) -> Void in
      make.right.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(60)
    }
    
    completeButton.setTitle("选取", forState: .Normal)
    completeButton.titleLabel?.font = UIFont.systemFontOfSize(18)
    completeButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    completeButton.addTarget(self, action: "onComplete", forControlEvents: .TouchUpInside)
    
    //selectedCountLabel
    cancelButton = UIButton()
    bottomBarContainerView.addSubview(cancelButton)
    cancelButton.snp_makeConstraints { (make) -> Void in
      make.left.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(60)
    }
    
    cancelButton.setTitle("取消", forState: .Normal)
    cancelButton.titleLabel?.font = UIFont.systemFontOfSize(18)
    cancelButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    cancelButton.addTarget(self, action: "onCancel", forControlEvents: .TouchUpInside)
    
    imageView = UIImageView()
    view.addSubview(imageView)
    imageView.snp_makeConstraints { (make) -> Void in
      make.centerX.equalTo(view)
      make.bottom.equalTo(view)
      make.width.height.equalTo(140)
    }
  }
  
}

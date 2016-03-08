//
//  PreviewPhotoViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/26.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PreviewPhotoViewController: WZPhotoBrowser {
  
  var topBarContainerView: UIView!
  var topBarTransparentView: UIView!
  var backButton: UIButton!
  var selectButton: UIControl!
  var unselectedImageView: UIImageView!
  var selectedImageView: UIImageView!
  
  var bottomBarContainerView: UIView!
  var bottomBarTransparentView: UIView!
  var completeButton: UIButton!
  var selectedCountLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initTopbar()
    initBottomBar()

  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if PhotosManager.sharedInstance.maxSelectedCount == 1 {
      
      selectButton.hidden = true
      unselectedImageView.hidden = true
      selectedImageView.hidden = true
      
    }
    
    updateCount()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    selectedCountLabel.setViewCornerRadius()

  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func onBack() {
    navigationController?.popViewControllerAnimated(true)
  }
  
  func onSelect() {
    setPhotoSelectedStatusWith(selectCellIndex)
    updateCount()
  }
  
  func onComplete() {
    
    let selectedCount = PhotosManager.sharedInstance.selectedIndexList.count
    
    //如果当前没有被选择的照片，则选择当前照片
    if selectedCount == 0 {
      PhotosManager.sharedInstance.selectPhotoWith(selectCellIndex)
    }
    
    PhotosManager.sharedInstance.didFinish()
  }
  
  override func onClickPhoto() {
    print(__FUNCTION__)
  }
  
  func initTopbar() {
    
    
    //topBarTransparentView
    topBarTransparentView = UIView()
    view.addSubview(topBarTransparentView)
    topBarTransparentView.snp_makeConstraints { (make) -> Void in
      make.top.right.left.equalTo(view)
      make.height.equalTo(64)
    }
    
    topBarTransparentView.alpha = 0.7
    topBarTransparentView.backgroundColor = UIColor.hexStringToColor("111111")
    
    //topBarContainer
    topBarContainerView = UIView()
    view.addSubview(topBarContainerView)
    topBarContainerView.snp_makeConstraints { (make) -> Void in
      make.top.right.left.equalTo(view)
      make.height.equalTo(64)
    }
    
    topBarContainerView.backgroundColor = UIColor.clearColor()
    
    //backButton
    backButton = UIButton()
    topBarContainerView.addSubview(backButton)
    backButton.snp_makeConstraints { (make) -> Void in
      make.top.bottom.left.equalTo(topBarContainerView)
      make.width.equalTo(50)
    }
    
    backButton.setImage(UIImage(named: "back_white_arrow"), forState: .Normal)
    backButton.addTarget(self, action: "onBack", forControlEvents: .TouchUpInside)
    
    //selectButton
    selectButton = UIControl()
    topBarContainerView.addSubview(selectButton)
    selectButton.snp_makeConstraints { (make) -> Void in
      make.right.equalTo(topBarContainerView).offset(-10)
      make.top.bottom.equalTo(topBarContainerView)
      make.width.equalTo(50)
    }
    
    selectButton.addTarget(self, action: "onSelect", forControlEvents: .TouchUpInside)
    
    //unselectedButton
    unselectedImageView = UIImageView()
    selectButton.addSubview(unselectedImageView)
    unselectedImageView.snp_makeConstraints { (make) -> Void in
      make.width.height.equalTo(26)
      make.center.equalTo(selectButton)
    }
    
    unselectedImageView.image = UIImage(named: "imagepick_unchecked")
    
    //selectedButton
    selectedImageView = UIImageView()
    selectButton.addSubview(selectedImageView)
    selectedImageView.snp_makeConstraints { (make) -> Void in
      make.width.height.equalTo(30)
      make.center.equalTo(selectButton)
    }
    
    selectedImageView.image = UIImage(named: "imagepick_checked")
    
  }
  
  func initBottomBar() {
    
    //bottomBarTransparentView
    bottomBarTransparentView = UIView()
    view.addSubview(bottomBarTransparentView)
    bottomBarTransparentView.snp_makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(44)
    }
    
    bottomBarTransparentView.alpha = 0.7
    bottomBarTransparentView.backgroundColor = UIColor.hexStringToColor("111111")
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp_makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(44)
    }
    
    bottomBarContainerView.backgroundColor = UIColor.clearColor()
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp_makeConstraints { (make) -> Void in
      make.right.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(50)
    }
    
    completeButton.setTitle("完成", forState: .Normal)
    completeButton.titleLabel?.font = UIFont.systemFontOfSize(16)
    completeButton.setTitleColor(UIColor.greenColor(), forState: .Normal)
    completeButton.addTarget(self, action: "onComplete", forControlEvents: .TouchUpInside)
    
    //selectedCountLabel
    selectedCountLabel = UILabel()
    bottomBarContainerView.addSubview(selectedCountLabel)
    selectedCountLabel.snp_makeConstraints { (make) -> Void in
      make.centerY.equalTo(bottomBarContainerView)
      make.right.equalTo(completeButton.snp_left)
      make.width.height.equalTo(20)
    }
    
    selectedCountLabel.textColor = UIColor.whiteColor()
    selectedCountLabel.backgroundColor = UIColor.hexStringToColor("03AC00")
    selectedCountLabel.textAlignment = .Center
    selectedCountLabel.font = UIFont.systemFontOfSize(14)
    
  }
  
  override func photoDidChange() {
    
    let isSelected = PhotosManager.sharedInstance.selectedIndexList.contains(selectCellIndex)
    setPhotoSelected(isSelected)
    updateCount()
    
  }
  
  func setPhotoSelectedStatusWith(index: Int) {
    
    let isSuccess = PhotosManager.sharedInstance.selectPhotoWith(index)
    
    if !isSuccess {
      
      let alert = UIAlertView(title: "", message: "你最多只能选择\(PhotosManager.sharedInstance.maxSelectedCount)张照片", delegate: nil, cancelButtonTitle: "我知道了")
      alert.show()
      
      return
    }
    
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(index)
    setPhotoStatusWithAnimation(isSelected)
  }
  
  func setPhotoStatusWithAnimation(isSelected: Bool) {
    
    self.setPhotoSelected(!isSelected)
    
    UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
      
      self.setPhotoSelected(isSelected)
      
      }) { _ in
        
    }
    
  }
  
  func setPhotoSelected(isSelected: Bool) {
    
    selectedImageView.transform = isSelected == false ? CGAffineTransformMakeScale(0.5, 0.5) : CGAffineTransformIdentity
    self.selectedImageView.alpha = CGFloat(isSelected)
    
  }
  
  private func updateCount() {
    
    let selectedCount = PhotosManager.sharedInstance.selectedIndexList.count
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.hidden = selectedCount == 0
    selectedCountLabel.text = countString
    
  }
}

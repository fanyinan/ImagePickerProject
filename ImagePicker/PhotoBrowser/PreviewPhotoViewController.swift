//
//  PreviewPhotoViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/26.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import Photos

class PreviewPhotoViewController: WZPhotoBrowserLite {
  
  private var topBarContainerView: UIView!
  private var topBarTransparentView: UIView!
  private var backButton: UIButton!
  private var selectButton: UIControl!
  private var unselectedImageView: UIImageView!
  private var selectedImageView: UIImageView!
  
  private var bottomBarContainerView: UIView!
  private var bottomBarTransparentView: UIView!
  private var completeButton: UIButton!
  private var selectedCountLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initTopbar()
    initBottomBar()

  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if PhotosManager.sharedInstance.maxSelectedCount == 1 {
      
      selectButton.isHidden = true
      unselectedImageView.isHidden = true
      selectedImageView.isHidden = true
      
    }
    
    updateCount()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    selectedCountLabel.layer.cornerRadius = selectedCountLabel.frame.size.height / 2
    selectedCountLabel.layer.masksToBounds = true

  }
  
  @objc func onBack() {
    _ = navigationController?.popViewController(animated: true)
  }
  
  @objc func onSelect() {
    
    PhotosManager.sharedInstance.checkImageIsInLocal(with: currentAsset) { isExistInLocal in
      
      guard isExistInLocal else { return }
      
      self.setPhotoSelectedStatusWith(self.currentIndex)
      self.updateCount()
    }
  }
  
  @objc func onComplete() {
    
    PhotosManager.sharedInstance.checkImageIsInLocal(with: currentAsset) { isExistInLocal in
      
      guard isExistInLocal else { return }
      
      //如果当前没有被选择的照片，则选择当前照片
      if PhotosManager.sharedInstance.selectedImages.isEmpty {
        PhotosManager.sharedInstance.selectPhoto(with: self.currentAsset)
      }
      
      PhotosManager.sharedInstance.didFinish()
    }
  }
  
  override func onClickPhoto() {
    print(#function)
  }
  
  func initTopbar() {
    
    
    //topBarTransparentView
    topBarTransparentView = UIView()
    view.addSubview(topBarTransparentView)
    topBarTransparentView.snp.makeConstraints { (make) -> Void in
      make.top.right.left.equalTo(view)
      make.height.equalTo(64)
    }
    
    topBarTransparentView.alpha = 0.7
    topBarTransparentView.backgroundColor = UIColor(hex: 0x111111)
    
    //topBarContainer
    topBarContainerView = UIView()
    view.addSubview(topBarContainerView)
    topBarContainerView.snp.makeConstraints { (make) -> Void in
      make.top.right.left.equalTo(view)
      make.height.equalTo(64)
    }
    
    topBarContainerView.backgroundColor = UIColor.clear
    
    //backButton
    backButton = UIButton()
    topBarContainerView.addSubview(backButton)
    backButton.snp.makeConstraints { (make) -> Void in
      make.top.bottom.left.equalTo(topBarContainerView)
      make.width.equalTo(50)
    }
    
    let image = UIImage(named: "back_white_arrow", in: Bundle(for: PreviewPhotoViewController.self), compatibleWith: nil)
    backButton.setImage(image, for: .normal)
    backButton.addTarget(self, action: #selector(PreviewPhotoViewController.onBack), for: .touchUpInside)
    
    //selectButton
    selectButton = UIControl()
    topBarContainerView.addSubview(selectButton)
    selectButton.snp.makeConstraints { (make) -> Void in
      make.right.equalTo(topBarContainerView).offset(-10)
      make.top.bottom.equalTo(topBarContainerView)
      make.width.equalTo(50)
    }
    
    selectButton.addTarget(self, action: #selector(PreviewPhotoViewController.onSelect), for: .touchUpInside)
    
    //unselectedButton
    unselectedImageView = UIImageView()
    selectButton.addSubview(unselectedImageView)
    unselectedImageView.snp.makeConstraints { (make) -> Void in
      make.width.height.equalTo(26)
      make.center.equalTo(selectButton)
    }
    
    unselectedImageView.image = UIImage(named: "imagepick_unchecked")
    
    //selectedButton
    selectedImageView = UIImageView()
    selectButton.addSubview(selectedImageView)
    selectedImageView.snp.makeConstraints { (make) -> Void in
      make.width.height.equalTo(30)
      make.center.equalTo(selectButton)
    }
    
    selectedImageView.image = UIImage(named: "imagepick_checked")
    
  }
  
  func initBottomBar() {
    
    //bottomBarTransparentView
    bottomBarTransparentView = UIView()
    view.addSubview(bottomBarTransparentView)
    bottomBarTransparentView.snp.makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(44)
    }
    
    bottomBarTransparentView.alpha = 0.7
    bottomBarTransparentView.backgroundColor = UIColor(hex: 0x111111)
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(44)
    }
    
    bottomBarContainerView.backgroundColor = UIColor.clear
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp.makeConstraints { (make) -> Void in
      make.right.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(50)
    }
    
    completeButton.setTitle("完成", for: UIControlState())
    completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    completeButton.setTitleColor(UIColor.green, for: UIControlState())
    completeButton.addTarget(self, action: #selector(PreviewPhotoViewController.onComplete), for: .touchUpInside)
    
    //selectedCountLabel
    selectedCountLabel = UILabel()
    bottomBarContainerView.addSubview(selectedCountLabel)
    selectedCountLabel.snp.makeConstraints { (make) -> Void in
      make.centerY.equalTo(bottomBarContainerView)
      make.right.equalTo(completeButton.snp.left)
      make.width.height.equalTo(20)
    }
    
    selectedCountLabel.textColor = UIColor.white
    selectedCountLabel.backgroundColor = UIColor(hex: 0x03AC00)
    selectedCountLabel.textAlignment = .center
    selectedCountLabel.font = UIFont.systemFont(ofSize: 14)
    
  }
  
  override func photoDidChange() {
    super.photoDidChange()
    
    let isSelected = PhotosManager.sharedInstance.selectedImages.contains(currentAsset)
    setPhotoSelected(isSelected)
    updateCount()
    
  }
  
  func setPhotoSelectedStatusWith(_ index: Int) {
    
    let isSuccess = PhotosManager.sharedInstance.selectPhoto(with: currentAsset)
    
    if !isSuccess {
      
      let alert = UIAlertView(title: "", message: "你最多只能选择\(PhotosManager.sharedInstance.maxSelectedCount)张照片", delegate: nil, cancelButtonTitle: "我知道了")
      alert.show()
      
      return
    }
    
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(with: currentAsset)
    setPhotoStatusWithAnimation(isSelected)
  }
  
  func setPhotoStatusWithAnimation(_ isSelected: Bool) {
    
    self.setPhotoSelected(!isSelected)
    
    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: UIViewAnimationOptions(), animations: { () -> Void in
      
      self.setPhotoSelected(isSelected)
      
      }) { _ in
        
    }
    
  }
  
  func setPhotoSelected(_ isSelected: Bool) {
    
    selectedImageView.transform = isSelected == false ? CGAffineTransform(scaleX: 0.5, y: 0.5) : CGAffineTransform.identity
    self.selectedImageView.alpha = isSelected ? 1 : 0
    
  }
  
  private func updateCount() {
    
    guard PhotosManager.sharedInstance.maxSelectedCount > 1 else {
      selectedCountLabel.isHidden = true
      return
    }
    
    let selectedCount = PhotosManager.sharedInstance.selectedImages.count
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.isHidden = selectedCount == 0
    selectedCountLabel.text = countString
    
  }
}

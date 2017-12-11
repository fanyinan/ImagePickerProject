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
  private var backButton: UIButton!
  private var selectButton: UIControl!
  private var unselectedImageView: UIImageView!
  private var selectedImageView: UIImageView!
  
  private var bottomBarContainerView: UIView!
  private var completeButton: UIButton!
  private var selectedCountLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initTopbar()
    initBottomBar()

  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if PhotosManager.shared.maxSelectedCount == 1 {
      
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
    
    if currentAsset.mediaType == .image {
      PhotosManager.shared.checkImageIsInLocal(with: currentAsset) { isExistInLocal in
        
        guard isExistInLocal else { return }
        
        self.setPhotoSelectedStatusWith(self.currentIndex)
        self.updateCount()

      }
    } else if currentAsset.mediaType == .video {
      
      PhotosManager.shared.checkVideoIsInLocal(with: currentAsset) { isExistInLocal in
        
        guard isExistInLocal else { return }
        
        self.setPhotoSelectedStatusWith(self.currentIndex)
        self.updateCount()

      }
    }
  }
  
  @objc func onComplete() {
    
    PhotosManager.shared.checkImageIsInLocal(with: currentAsset) { isExistInLocal in
      
      guard isExistInLocal else { return }
      
      //如果当前没有被选择的照片，则选择当前照片
      if PhotosManager.shared.selectedImages.isEmpty {
        PhotosManager.shared.select(with: self.currentAsset)
      }
      
      PhotosManager.shared.didFinish()
    }
  }
  
  override func onClickPhoto() {
    print(#function)
  }
  
  func initTopbar() {
    
    //topBarContainer
    topBarContainerView = UIView()
    topBarContainerView.backgroundColor = UIColor(hex: 0x111111).withAlphaComponent(0.7)
    view.addSubview(topBarContainerView)
    topBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.left.equalToSuperview()
      make.top.equalToSuperview()
      if #available(iOS 11.0, *) {
        make.height.equalTo(40 + navigationController!.view.safeAreaInsets.top)
      } else {
        make.height.equalTo(64)
      }
    }
    
    //backButton
    backButton = UIButton()
    topBarContainerView.addSubview(backButton)
    backButton.snp.makeConstraints { (make) -> Void in
      make.bottom.left.equalTo(topBarContainerView)
      make.width.height.equalTo(50)
    }
    
    let image = UIImage(named: "back_white_arrow", in: Bundle(for: PreviewPhotoViewController.self), compatibleWith: nil)
    backButton.setImage(image, for: .normal)
    backButton.addTarget(self, action: #selector(PreviewPhotoViewController.onBack), for: .touchUpInside)
    
    //selectButton
    selectButton = UIControl()
    topBarContainerView.addSubview(selectButton)
    selectButton.snp.makeConstraints { (make) -> Void in
      make.right.equalTo(topBarContainerView).offset(-10)
      make.bottom.equalTo(topBarContainerView)
      make.width.height.equalTo(50)
    }
    
    selectButton.addTarget(self, action: #selector(PreviewPhotoViewController.onSelect), for: .touchUpInside)
    
    //unselectedButton
    unselectedImageView = UIImageView()
    selectButton.addSubview(unselectedImageView)
    unselectedImageView.snp.makeConstraints { (make) -> Void in
      make.width.height.equalTo(26)
      make.center.equalTo(selectButton)
    }
    
    unselectedImageView.image = UIImage(named: "imagepick_unchecked", in: Bundle(for: PreviewPhotoViewController.self), compatibleWith: nil)
    
    //selectedButton
    selectedImageView = UIImageView()
    selectButton.addSubview(selectedImageView)
    selectedImageView.snp.makeConstraints { (make) -> Void in
      make.width.height.equalTo(30)
      make.center.equalTo(selectButton)
    }
    
    selectedImageView.image = UIImage(named: "imagepick_checked", in: Bundle(for: PreviewPhotoViewController.self), compatibleWith: nil)
    
  }
  
  func initBottomBar() {
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    bottomBarContainerView.backgroundColor = UIColor(hex: 0x111111).withAlphaComponent(0.7)

    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.left.equalTo(view)
      make.bottom.equalTo(view)
      if #available(iOS 11.0, *) {
        make.height.equalTo(20 + navigationController!.view.layoutMargins.bottom)
      } else {
        make.height.equalTo(44)
      }
    }
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp.makeConstraints { (make) -> Void in
      make.top.equalTo(bottomBarContainerView)
      make.right.equalToSuperview().offset(-navigationController!.view.layoutMargins.right)
      make.width.height.equalTo(50)
    }
    
    completeButton.setTitle("完成", for: .normal)
    completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    completeButton.setTitleColor(.white, for: .normal)
    completeButton.addTarget(self, action: #selector(PreviewPhotoViewController.onComplete), for: .touchUpInside)
    
    //selectedCountLabel
    selectedCountLabel = UILabel()
    bottomBarContainerView.addSubview(selectedCountLabel)
    selectedCountLabel.snp.makeConstraints { (make) -> Void in
      make.centerY.equalTo(completeButton)
      make.right.equalTo(completeButton.snp.left)
      make.width.height.equalTo(20)
    }
    
    selectedCountLabel.textColor = UIColor.white
    selectedCountLabel.backgroundColor = UIColor(hex: 0xFFE972)
    selectedCountLabel.textAlignment = .center
    selectedCountLabel.font = UIFont.systemFont(ofSize: 14)
    
  }
  
  override func photoDidChange() {
    super.photoDidChange()
    
    let isSelected = PhotosManager.shared.getAssetSelectedStatus(with: currentAsset)
    setPhotoSelected(isSelected)
    updateCount()
    
  }
  
  func setPhotoSelectedStatusWith(_ index: Int) {
    
    let isSuccess = PhotosManager.shared.select(with: currentAsset)
    
    if !isSuccess {
      
      let alert = UIAlertView(title: "", message: "你最多只能选择\(PhotosManager.shared.maxSelectedCount)张文件", delegate: nil, cancelButtonTitle: "我知道了")
      alert.show()
      
      return
    }
    
    let isSelected = PhotosManager.shared.getAssetSelectedStatus(with: currentAsset)
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
    
    guard PhotosManager.shared.maxSelectedCount > 1 else {
      selectedCountLabel.isHidden = true
      return
    }
    
    let selectedCount = PhotosManager.shared.selectedImages.count
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.isHidden = selectedCount == 0
    selectedCountLabel.text = countString
    
  }
}

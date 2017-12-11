//
//  PhotoThumbCell.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import Photos

class PhotoThumbCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var selectedStatusContainerView: UIView!
  @IBOutlet weak var selectedImageView: UIImageView!
  @IBOutlet weak var unselectedImageView: UIImageView!
  @IBOutlet weak var selectedButton: UIControl!
  @IBOutlet weak var durationLabel: UILabel!
  
  private(set) var isInICloud = false
  
  private var asset: PHAsset!
  
  weak var photoColletionViewController: PhotoColletionViewController?
  
  @IBAction func onClickRadio() {

    guard let vc = photoColletionViewController else { return }
    
    if asset.mediaType == .image {
      PhotosManager.shared.checkImageIsInLocal(with: asset) { isExistInLocal in
        
        guard isExistInLocal else { return }
        
        self.setResourceSelectedStatus()
        vc.updateUI()
        
      }
    } else if asset.mediaType == .video {
      
      PhotosManager.shared.checkVideoIsInLocal(with: asset) { isExistInLocal in
        
        guard isExistInLocal else { return }
        
        self.setResourceSelectedStatus()
        vc.updateUI()
        
      }
    }
  }
  
  func setAsset(_ asset: PHAsset) {
    
    self.asset = asset

    updateSelectedStatus()
    updateIsSelectable()

    let currentTag = tag + 1
    tag = currentTag
    
    
    imageView.image = nil
    
    PhotosManager.shared.fetchImage(with: asset, sizeType: .thumbnail) { (image, isInICloud) in
      
      guard image != nil else {
        return
      }
      
      if currentTag == self.tag {
        
        self.imageView.image = image
        self.isInICloud = isInICloud
        
      }
    }
  }
  
  func setPhotoStatusWithAnimation(_ isSelected: Bool) {
    
    self.setResourceSelected(!isSelected)
    
    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: UIViewAnimationOptions(), animations: { () -> Void in
      
      self.setResourceSelected(isSelected)
      
    }, completion: nil)
    
  }
  
  func updateSelectedStatus() {
    
    let isSelected = PhotosManager.shared.getAssetSelectedStatus(with: asset)
    setResourceSelected(isSelected)
    
    if asset.mediaType == .video {
      
      durationLabel.text = formatSecond(second: Int(round(asset.duration)))
      
    } else {
      
      durationLabel.text = ""
      
    }
  }
  
  func updateIsSelectable() {
    
    if PhotosManager.shared.maxSelectedCount == 1 && !PhotosManager.shared.resourceOption.contains(.video) {
      
      selectedButton.isHidden = true
      unselectedImageView.isHidden = true
      selectedImageView.isHidden = true
      
      return
    }
    
    var isHide = true
    
    if asset.mediaType == .video {
      isHide = !PhotosManager.shared.selectedImages.isEmpty
    } else if asset.mediaType == .image {
      isHide = !PhotosManager.shared.selectedVideos.isEmpty
    }
    
    selectedStatusContainerView.isHidden = isHide
    selectedButton.isHidden = isHide
  }
  
  private func setResourceSelected(_ isSelected: Bool) {
    
//    if PhotosManager.shared.maxSelectedCount == 1, PhotosManager.shared.op {
//
//      selectedButton.isHidden = true
//      unselectedImageView.isHidden = true
//      selectedImageView.isHidden = true
//
//      return
//    }
    
    selectedImageView.isHidden = false
    unselectedImageView.isHidden = false
    
    selectedImageView.transform = isSelected == false ? CGAffineTransform(scaleX: 0.5, y: 0.5) : CGAffineTransform.identity
    self.selectedImageView.alpha = isSelected ? 1 : 0
    
  }
  
  private func formatSecond(second: Int) -> String {
    
    let hour = second / (60 * 60)
    let minute = second % (60 * 60) / 60
    let second = second % 60

    let hourStr = String(format: "%02d", hour)
    let minuteStr = String(format: "%02d", minute)
    let secondStr = String(format: "%02d", second)

    if hour == 0 {
      return minuteStr + ":" + secondStr
    } else {
      return hourStr + ":" + minuteStr + ":" + secondStr
    }
  }
  
  private func setResourceSelectedStatus() {
    
    
    let isSuccess = PhotosManager.shared.select(with: asset)
    
    if !isSuccess {
      
      if PhotosManager.shared.maxSelectedCount == 1 {
        
        if let selectedAsset = PhotosManager.shared.selectedVideos.first ?? PhotosManager.shared.selectedImages.first {
          PhotosManager.shared.select(with: selectedAsset)
          PhotosManager.shared.select(with: asset)
        }
        
      } else {
        
        let alert = UIAlertView(title: "", message: "最多只能选择\(PhotosManager.shared.maxSelectedCount)个文件", delegate: nil, cancelButtonTitle: "知道了")
        alert.show()
        
        return
      }
    }
    
    let isSelected = PhotosManager.shared.getAssetSelectedStatus(with: asset)
    setPhotoStatusWithAnimation(isSelected)
  }
}

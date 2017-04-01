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
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  @IBAction func onClickRadio() {

    guard let vc = photoColletionViewController else { return }
    
    PhotosManager.sharedInstance.checkImageIsInICloud(with: asset) { isInICloud in
    
      guard !isInICloud else { return }

      self.setResourceSelectedStatus()
      vc.updateUI()
      
    }
  }
  
  func setAsset(_ asset: PHAsset) {
    
    self.asset = asset

    updateSelectedStatus()
    updateIsSelectable()

    let currentTag = tag + 1
    tag = currentTag
    
    
    imageView.image = nil
    
    PhotosManager.sharedInstance.fetchImage(with: asset, sizeType: .thumbnail) { (image, isInICloud) in
      
      guard image != nil else {
        return
      }
      
      if currentTag == self.tag {
        
        self.imageView.image = image
        self.isInICloud = isInICloud
        
      }
    }
  }
  
  func setResourceSelectedStatus() {
    
    guard asset.mediaType == .image else {
      let isSelected = PhotosManager.sharedInstance.selectVideo(with: asset)
      setPhotoStatusWithAnimation(isSelected)
      return
    }
    
    let isSuccess = PhotosManager.sharedInstance.selectPhoto(with: asset)
    
    if !isSuccess {
      
      let alert = UIAlertView(title: "", message: "你最多只能选择\(PhotosManager.sharedInstance.maxSelectedCount)张照片", delegate: nil, cancelButtonTitle: "我知道了")
      alert.show()
      
      return
    }
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(with: asset)
    setPhotoStatusWithAnimation(isSelected)
  }
  
  func setPhotoStatusWithAnimation(_ isSelected: Bool) {
    
    self.setResourceSelected(!isSelected)
    
    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: UIViewAnimationOptions(), animations: { () -> Void in
      
      self.setResourceSelected(isSelected)
      
    }) { _ in
      
    }
    
  }
  
  func updateSelectedStatus() {
    
    if asset.mediaType == .video {
      
      durationLabel.text = formatSecond(second: Int(round(asset.duration)))
      if let selectedVideo = PhotosManager.sharedInstance.selectedVideo, selectedVideo == asset {
        setResourceSelected(true)
      } else {
        setResourceSelected(false)
      }
      
    } else {
      
      let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(with: asset)
      setResourceSelected(isSelected)
      durationLabel.text = ""
      
    }
  }
  
  func updateIsSelectable() {
    
    if asset.mediaType == .video {
      
      let isHide = !PhotosManager.sharedInstance.selectedImages.isEmpty
      selectedStatusContainerView.isHidden = isHide
      selectedButton.isHidden = isHide
      
    } else if asset.mediaType == .image {
      
      let isHide = !(PhotosManager.sharedInstance.selectedVideo == nil)
      selectedStatusContainerView.isHidden = isHide
      selectedButton.isHidden = isHide

    }
  }
  
  func setResourceSelected(_ isSelected: Bool) {
    
    if PhotosManager.sharedInstance.maxSelectedCount == 1 {
      
      selectedButton.isHidden = true
      unselectedImageView.isHidden = true
      selectedImageView.isHidden = true
      
      return
    }
    selectedImageView.isHidden = false
    unselectedImageView.isHidden = false
    
    selectedImageView.transform = isSelected == false ? CGAffineTransform(scaleX: 0.5, y: 0.5) : CGAffineTransform.identity
    self.selectedImageView.alpha = isSelected ? 1 : 0
    
  }
  
  func formatSecond(second: Int) -> String {
    
    let hour = second / (60 * 60)
    let minute = second % (60 * 60) / 60
    let second = second % (60 * 60 * 60)

    let hourStr = String(format: "%02d", hour)
    let minuteStr = String(format: "%02d", minute)
    let secondStr = String(format: "%02d", second)

    if hour == 0 {
      return minuteStr + ":" + secondStr
    } else {
      return hourStr + ":" + minuteStr + ":" + secondStr
    }
  }
}

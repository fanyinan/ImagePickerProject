//
//  PhotoThumbCell.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PhotoThumbCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var selectedImageView: UIImageView!
  @IBOutlet weak var unselectedImageView: UIImageView!
  @IBOutlet weak var selectedButton: UIControl!
  
  private(set) var isInICloud = false
  private var imageRequestID: Int32 = 0
  weak var photoColletionViewController: PhotoColletionViewController?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  @IBAction func onClickRadio() {

    guard let vc = photoColletionViewController else { return }
    
    let indexPath = vc.collectionView.indexPath(for: self)!
    
    PhotosManager.sharedInstance.checkImageIsInICloud(with: indexPath.row - 1) { isInICloud in
    
      guard !isInICloud else { return }

      self.setPhotoSelectedStatusWith(indexPath.row - 1)
      vc.updateUI()
      
    }
  }
  
  func setImageWith(_ index: Int) {
    
    let currentTag = tag + 1
    tag = currentTag
    
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(index)
    self.setPhotoSelected(isSelected)
    
    imageView.image = nil
    
    PhotosManager.sharedInstance.cancelRequestImage(with: imageRequestID)
    
    PhotosManager.sharedInstance.getImageInCurrentAlbumWith(index, withSizeType: .thumbnail, handleCompletion: { (image, isInICloud) -> Void in
      
      guard image != nil else {
        return
      }
      
      if currentTag == self.tag {
        
        self.imageView.image = image
        self.isInICloud = isInICloud
        
      }
      
    }) { imageRequestID in
      
      self.imageRequestID = imageRequestID
    }
  }
  
  func setPhotoSelectedStatusWith(_ index: Int) {
    
    let isSuccess = PhotosManager.sharedInstance.selectPhotoWith(index)
    
    if !isSuccess {
      
      let alert = UIAlertView(title: "", message: "你最多只能选择\(PhotosManager.sharedInstance.maxSelectedCount)张照片", delegate: nil, cancelButtonTitle: "我知道了")
      alert.show()
      
      return
    }
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(index)
    setPhotoStatusWithAnimation(isSelected)
  }
  
  func setPhotoStatusWithAnimation(_ isSelected: Bool) {
    
    self.setPhotoSelected(!isSelected)
    
    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: UIViewAnimationOptions(), animations: { () -> Void in
      
      self.setPhotoSelected(isSelected)
      
    }) { _ in
      
    }
    
  }
  
  func setPhotoSelected(_ isSelected: Bool) {
    
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
  
}

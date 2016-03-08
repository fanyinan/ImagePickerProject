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
  
  var onRadio: ((PhotoThumbCell) -> Void)?
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  @IBAction func onClickRadio() {
    onRadio?(self)
  }
  
  func setImageWith(index: Int) {
    
    let currentTag = tag + 1
    tag = currentTag
    
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(index)
    self.setPhotoSelected(isSelected)
    
    PhotosManager.sharedInstance.getImageInCurrentAlbumWith(index, withSizeType: .Thumbnail) { (image) -> Void in
      
      guard image != nil else {
        return
      }
      
      if currentTag == self.tag {
        
        self.imageView.image = image
        
      }
    }
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
    
    UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .CurveEaseInOut, animations: { () -> Void in
      
      self.setPhotoSelected(isSelected)
      
      }) { _ in
        
    }
    
  }
  
  func setPhotoSelected(isSelected: Bool) {
    
    if PhotosManager.sharedInstance.maxSelectedCount == 1 {

      selectedButton.hidden = true
      unselectedImageView.hidden = true
      selectedImageView.hidden = true
      
      return
    }
    selectedImageView.hidden = false
    unselectedImageView.hidden = false
    
    selectedImageView.transform = isSelected == false ? CGAffineTransformMakeScale(0.5, 0.5) : CGAffineTransformIdentity
    self.selectedImageView.alpha = CGFloat(isSelected)
    
  }
  
  func setAsCamera() {
    
    selectedImageView.hidden = true
    unselectedImageView.hidden = true
    imageView.image = UIImage(named: "imagepick_camera")
    
  }
}

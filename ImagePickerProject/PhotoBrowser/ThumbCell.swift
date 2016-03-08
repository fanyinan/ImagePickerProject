//
//  ThumbCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/10/29.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class ThumbCell: UITableViewCell {
  
  @IBOutlet var thumbImageView: UIImageView!
  @IBOutlet weak var leftMarginConstraint: NSLayoutConstraint!
  @IBOutlet weak var rightMarginConstraint: NSLayoutConstraint!

  
  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = UIColor.blackColor()
    thumbImageView.setViewCornerRadius(2)
  }
  
  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func setImageWith(imgUrl imgUrl: String) {
    thumbImageView.url = imgUrl
  }
  
  func setImageWith(image image: UIImage) {
    thumbImageView.image = image
  }
  
  func setBorderWidth(width: CGFloat) {
    leftMarginConstraint.constant = width
    rightMarginConstraint.constant = width

  }
  
}

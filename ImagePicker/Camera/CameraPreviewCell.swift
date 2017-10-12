//
//  PhotoCameraPreviewCell.swift
//  ImagePickerProject
//
//  Created by 范祎楠 on 16/7/6.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class CameraPreviewCell: UICollectionViewCell {
  
  @IBOutlet weak var cameraPreviewView: CameraPreviewView!
  
  override func awakeFromNib() {
    super.awakeFromNib()

    cameraPreviewView.startPreview()
    
  }
}

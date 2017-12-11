//
//  PhotoCollectionCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/6/9.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit
import Photos

class PhotoCollectionLiteCell: UICollectionViewCell {
  
  private(set) var zoomImageScrollView: ZoomImageScrollViewLite!
  private var maskButton: UIControl!
  private var playImageView: UIImageView!
  private var asset: PHAsset!
  private var videoPlayView: VideoPlayView?

  var padding: CGFloat = 0 {
    didSet{
      zoomImageScrollView.frame = CGRect(x: padding, y: 0, width: frame.width - padding * CGFloat(2), height: frame.height)
    }
  }
 
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    zoomImageScrollView = ZoomImageScrollViewLite()
    zoomImageScrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    contentView.addSubview(zoomImageScrollView)
    
    maskButton = UIControl(frame: bounds)
    maskButton.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    maskButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    maskButton.addTarget(self, action: #selector(onPlay), for: .touchUpInside)
    contentView.addSubview(maskButton)

    playImageView = UIImageView()
    maskButton.addSubview(playImageView)
    playImageView.snp.makeConstraints { make in
      make.width.height.equalTo(60)
      make.center.equalToSuperview()
    }
    
    playImageView.image = UIImage(named: "play", in: Bundle(for: PreviewPhotoViewController.self), compatibleWith: nil)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setData(_ asset: PHAsset) {
   
    self.asset = asset
    
    maskButton.isHidden = asset.mediaType == .image
    
    let currentTag = tag + 1
    tag = currentTag
    
    PhotosManager.shared.fetchImage(with: asset, sizeType: .preview, handleCompletion: { (image: UIImage?, isInICloud) -> Void in
      
      guard currentTag == self.tag else {
        
        return
      }
      
      self.zoomImageScrollView.setImage(image == nil ? UIImage(named: "default_pic") : image)
      
    })
  }
  
  func pause() {
    
    videoPlayView?.isHidden = true
    videoPlayView?.pause()
    maskButton.isHidden = false

  }
  
  @objc private func onPlay() {
    
    maskButton.isHidden = true

    PhotosManager.shared.fetchVideo(videoAsset: asset) { [weak self ] (asset, _) in
      
      guard let strongSelf = self else { return }
      guard let asset = asset else { return }
     
      let videoPlayView = VideoPlayView(frame: strongSelf.bounds)
      strongSelf.contentView.addSubview(videoPlayView)
      
      videoPlayView.play(with: asset) { [weak self] in
        
        self?.maskButton.isHidden = false
        
      }
      
      strongSelf.videoPlayView = videoPlayView
    }
  }
}

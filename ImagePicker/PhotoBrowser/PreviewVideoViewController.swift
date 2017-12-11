//
//  PreviewVideoViewController.swift
//  ImagePickerProject
//
//  Created by fanyinan on 2017/12/11.
//  Copyright © 2017年 范祎楠. All rights reserved.
//

import UIKit
import Photos

class PreviewVideoViewController: UIViewController {

  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var completeButton: UIButton!
  @IBOutlet weak var videoPlayView: VideoPlayView!
  @IBOutlet weak var pauseView: UIView!
  @IBOutlet weak var previewImageView: UIImageView!
  @IBOutlet weak var topBarHightConstraint: NSLayoutConstraint!

  var asset: PHAsset!
  
  override func loadView() {
    UINib(nibName: "PreviewVideoViewController", bundle: Bundle(for: PreviewPhotoViewController.self)).instantiate(withOwner: self, options: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 11.0, *) {
      topBarHightConstraint.constant = 40 + navigationController!.view.safeAreaInsets.top
    }
    
    PhotosManager.shared.fetchImage(with: asset, sizeType: .preview, handleCompletion: { (image: UIImage?, isInICloud) -> Void in
      
      self.previewImageView.image = image == nil ? UIImage(named: "default_pic") : image
      
    })
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: true)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    pause()

  }
  
  @IBAction func onPlay() {
    
    PhotosManager.shared.fetchVideo(videoAsset: asset) { [weak self ] (asset, _) in

      guard let asset = asset else { return }

      self?.pauseView.isHidden = true

      self?.videoPlayView.play(with: asset) { [weak self] in

        self?.pauseView.isHidden = false

      }
    }
  }
  
  @IBAction func onPop() {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func onComplete() {
      
    if let selectedAsset = PhotosManager.shared.selectedVideos.first {
      PhotosManager.shared.select(with: selectedAsset)
    }
    
    PhotosManager.shared.select(with: asset)
      
    PhotosManager.shared.didFinish()
    
  }
  
  private func pause() {
    
    videoPlayView.pause()
    pauseView.isHidden = false
    
  }
}

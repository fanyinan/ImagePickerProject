//
//  VideoPlayView.swift
//  ImagePickerProject
//
//  Created by fanyinan on 2017/12/9.
//  Copyright © 2017年 范祎楠. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayView: UIView {

  private var playerItem: AVPlayerItem?
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var onFinish: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,object: playerItem)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,object: playerItem)

  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func play(with asset: AVAsset, onFinish: @escaping () -> Void) {
    
    self.onFinish = onFinish
    
    self.playerLayer?.removeFromSuperlayer()
    playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = layer.bounds
    playerLayer.videoGravity = .resizeAspect
    layer.addSublayer(playerLayer)
    self.playerLayer = playerLayer
    player?.play()
    
  }
  
  func pause() {
    
    player?.pause()
    
  }
  
  @objc private func moviePlayDidEnd(_ notificaton: Notification) {
    
    guard let playerItemInNotification = notificaton.object as? AVPlayerItem else { return }
    guard let playerItem = self.playerItem, playerItem == playerItemInNotification else { return }
    
    onFinish?()
  }

}

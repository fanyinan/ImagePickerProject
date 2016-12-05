//
//  PhotoColletionViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import Photos

class PhotoColletionViewController: UIViewController {
  
  fileprivate var collectionView: UICollectionView!
  fileprivate var selectedCountLabel: UILabel!
  fileprivate var completionLabel: UILabel!
  fileprivate var completionButton: UIControl!
  fileprivate var ablumButton: UIControl!
  fileprivate var titleLabel: UILabel!
  fileprivate var indicatorImageView: UIImageView!
  
  fileprivate var imageWidth: CGFloat!
  fileprivate var selectItemNum = 0
  fileprivate var popViewHelp: PopViewHelper!
  fileprivate var ablumView: UIView!
  fileprivate var cellFadeAnimation = false
  
  fileprivate let thumbIdentifier = "PhotoThumbCell"
  fileprivate let previewIdentifier = "CameraPreviewCell"

  fileprivate let midSpace: CGFloat = 2
  fileprivate let rowCount = 3
  fileprivate let ablumButtonWidth: CGFloat = 120
  fileprivate let selectedCountLabelWidth: CGFloat = 20
  fileprivate let indicatorWidth: CGFloat = 15
  
  var canOpenCamera = true
  var cameraHelper: CameraHelper!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    initView()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.reloadData()
    
    updateUI()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    imageWidth = (view.frame.width - midSpace * CGFloat(rowCount - 1)) / CGFloat(rowCount)
    
    let scale = UIScreen.main.scale
    PhotosManager.assetGridThumbnailSize = CGSize(width: imageWidth * scale, height: imageWidth * scale)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func onRadio(_ cell: PhotoThumbCell) {
    
    let indexPath = collectionView.indexPath(for: cell)!
    cell.setPhotoSelectedStatusWith((indexPath as NSIndexPath).row - 1)
    
    updateUI()
  }
  
  func completeButtonClick() {
    
    PhotosManager.sharedInstance.didFinish()
    
  }
  
  func albumButtonClick() {
    
    if popViewHelp.isShow {
      popViewHelp.hidePopView()
    } else {
      popViewHelp.showPopView()
    }
    
  }
  
  func onCancel() {
    
    PhotosManager.sharedInstance.cancel()
    dismiss(animated: true, completion: nil)
  }
  
  func goToPhotoBrowser() {
    
    let photoBrowser = PreviewPhotoViewController(delegate: self, quitBlock: { () -> Void in
      self.navigationController?.popViewController(animated: true)
    })
    photoBrowser.delegate = self
    navigationController?.pushViewController(photoBrowser, animated: true)
    
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
   //MARK: - private Implements
  
  fileprivate func initView() {
    
    initAblum()
    initNavigationBarButton()
    
    let collectionViewFlowLayout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewFlowLayout)
    collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    collectionView.backgroundColor = UIColor.white
    collectionView.register(UINib(nibName: thumbIdentifier, bundle: nil), forCellWithReuseIdentifier: thumbIdentifier)
    collectionView.register(UINib(nibName: previewIdentifier, bundle: nil), forCellWithReuseIdentifier: previewIdentifier)

    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)
    
    initCompletionButton()

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(PhotoColletionViewController.onCancel))
    
  }
  
  fileprivate func initNavigationBarButton() {
    
    ablumButton = UIControl(frame: CGRect(x: 0 , y: 0, width: ablumButtonWidth, height: 44))
    navigationItem.titleView = ablumButton
    
    ablumButton.addTarget(self, action: #selector(PhotoColletionViewController.albumButtonClick), for: .touchUpInside)
    
    titleLabel = UILabel()
    ablumButton.addSubview(titleLabel)
    titleLabel.snp_makeConstraints { (make) in
      make.center.equalTo(ablumButton)
    }
    
    titleLabel.textColor = UIColor.hexStringToColor("368EFF")
    titleLabel.font = UIFont.systemFont(ofSize: 18)
    titleLabel.textAlignment = .center
    
    updateTitle()

    indicatorImageView = UIImageView()
    ablumButton.addSubview(indicatorImageView)
    indicatorImageView.snp_makeConstraints { (make) in
      make.left.equalTo(titleLabel.snp_right).offset(5)
      make.centerY.equalTo(ablumButton)
      make.width.height.equalTo(indicatorWidth)
    }
    
    indicatorImageView.contentMode = .scaleAspectFit
    indicatorImageView.image = UIImage(named: "ic_down_arrow")
    
  }
  
  fileprivate func initAblum() {
  
    ablumView = PhotoAlbumView(frame: view.bounds, delegate: self)
    popViewHelp = PopViewHelper(superView: view, targetView: ablumView, viewPopDirection: .above, maskStatus: .normal)
    popViewHelp.showAnimateDuration = 0.35
    popViewHelp.hideAnimateDuration = 0.35
    popViewHelp.alpha = [0, 1, 1]
    popViewHelp.delegate = self
    
  }
  
  fileprivate func initCompletionButton() {
  
    completionButton = UIControl(frame: CGRect(x: view.frame.width - 60, y: 0, width: 60, height: 44))
    completionButton.addTarget(self, action: #selector(PhotoColletionViewController.completeButtonClick), for: .touchUpInside)
    navigationController?.navigationBar.addSubview(completionButton)
    
    selectedCountLabel = UILabel(frame: CGRect(x: 0, y: (completionButton.frame.height - selectedCountLabelWidth) / 2, width: selectedCountLabelWidth, height: selectedCountLabelWidth))
    selectedCountLabel.backgroundColor = UIColor.hexStringToColor("03AC00")
    selectedCountLabel.font = UIFont.systemFont(ofSize: 14)
    selectedCountLabel.textColor = UIColor.white
    selectedCountLabel.textAlignment = .center
    selectedCountLabel.setViewCornerRadius()
    completionButton.addSubview(selectedCountLabel)
    
    completionLabel = UILabel(frame: CGRect(x: selectedCountLabelWidth, y: 0, width: completionButton.frame.width - selectedCountLabelWidth, height: 44))
    completionLabel.textColor = UIColor.hexStringToColor("03AC00")
    completionLabel.text = "完成"
    completionLabel.font = UIFont.systemFont(ofSize: 14)
    completionLabel.textAlignment = .center
    completionButton.addSubview(completionLabel)
    
  }
  
  fileprivate func checkCamera(){
    
    let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
    if (AVAuthorizationStatus.denied == authStatus || AVAuthorizationStatus.restricted == authStatus){
      
      let alertController = UIAlertController(title: "相机被禁用", message: "请在设置－隐私－相机中开启", preferredStyle: .alert)
      let okAction = UIAlertAction(title: "确定", style: .default, handler: nil)
      alertController.addAction(okAction)
      present(alertController, animated: true, completion: nil)
    }
  }
  
  fileprivate func getPhotoFromCamera(){
    
    if cameraHelper == nil {
      cameraHelper = CameraHelper(handlerViewController: self)
    }
    
    cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Push
    cameraHelper.isCrop = PhotosManager.sharedInstance.isCrop
    cameraHelper.openCamera()
  }
  
  fileprivate func updateUI() {
    
    let selectedCount = PhotosManager.sharedInstance.selectedIndexList.count
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.isHidden = selectedCount == 0
    selectedCountLabel.text = countString
    
    completionLabel.isEnabled = selectedCount != 0
    completionButton.isEnabled = selectedCount != 0
    
  }

  fileprivate func updateTitle() {
    
    if let currentAlbumIndex = PhotosManager.sharedInstance.currentAlbumIndex {
      let title = PhotosManager.sharedInstance.getAlbumWith(currentAlbumIndex)?.localizedTitle ?? "相册"
      titleLabel.text = title
      
    }
  }
  
  fileprivate func animateIndicator(_ isIndicatShowing: Bool) {
    
    UIView.animate(withDuration: 0.3, animations: { 
      
      let transform = CGAffineTransform(rotationAngle: isIndicatShowing ? CGFloat(M_PI) : 0)
      self.indicatorImageView.transform = transform
      
    }) 
  }
}

extension PhotoColletionViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    var photoNum = PhotosManager.sharedInstance.getImageCountInCurrentAlbum()
    
    if canOpenCamera {
      photoNum += 1
    }
    return photoNum
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let row = (indexPath as NSIndexPath).row
    let showPreview = canOpenCamera && row == 0
    
    let identifier = showPreview ? previewIdentifier : thumbIdentifier
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    
    if !showPreview {
      
      let thumbCell = cell as! PhotoThumbCell
      thumbCell.onRadio = onRadio
      thumbCell.setImageWith(canOpenCamera == true ? (indexPath as NSIndexPath).row - 1 : (indexPath as NSIndexPath).row)
      
    }
    
    return cell
  }
}

extension PhotoColletionViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: imageWidth, height: imageWidth)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return midSpace
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return midSpace
  }
}

extension PhotoColletionViewController: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    let row = (indexPath as NSIndexPath).row
    
    if canOpenCamera && row == 0 {
      
      getPhotoFromCamera()
      
    } else {
      
      if PhotosManager.sharedInstance.isCrop {
        
        self.navigationController?.pushViewController(PhotoCropViewController(imageIndex: canOpenCamera == true ? (indexPath as NSIndexPath).row - 1 : (indexPath as NSIndexPath).row), animated: true)
        
      } else {
        
        selectItemNum = canOpenCamera == true ? (indexPath as NSIndexPath).row - 1 : (indexPath as NSIndexPath).row
        goToPhotoBrowser()
        
      }
      
    }
  }
}

extension PhotoColletionViewController: PhotoAlbumViewDelegate {
  
  func photoAlbumView(_ photoAlbumView: PhotoAlbumView, didSelectAtIndex index: Int) {
    updateTitle()
    popViewHelp.hidePopView()
    collectionView.reloadData()
    cellFadeAnimation = true


  }
  
  @objc(collectionView:willDisplayCell:forItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

    guard cellFadeAnimation else { return }
    
    cell.alpha = 0
    
    UIView.animate(withDuration: 0.3, animations: { 
      
      cell.alpha = 1

      }, completion: { finish in
        
      self.cellFadeAnimation = false

    }) 
  }
}

extension PhotoColletionViewController: WZPhotoBrowserLiteDelegate {
  
  func numberOfImage(_ photoBrowser: WZPhotoBrowserLite) -> Int {
    
    return PhotosManager.sharedInstance.getImageCountInCurrentAlbum()
    
  }
  
  func firstDisplayIndex(_ photoBrowser: WZPhotoBrowserLite) -> Int {
    
    return selectItemNum
  }
}

extension PhotoColletionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    let type : String = info[UIImagePickerControllerMediaType] as! String
    
    if type == "public.image" {
      
      let image : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
      
      if PhotosManager.sharedInstance.isCrop {
        
        picker.dismiss(animated: false, completion: nil)
        
        navigationController?.pushViewController(PhotoCropViewController(image: image), animated: true)
        
      } else {
        
        picker.dismiss(animated: true, completion: nil)
        
        PhotosManager.sharedInstance.didFinish(image)
        
      }
    }
  }
}

extension PhotoColletionViewController: PopViewHelperDelegate {
  
  func popViewHelper(_ popViewHelper: PopViewHelper, shouldShowPopView targetView: UIView) {
    
    animateIndicator(true)
  }
  
  func popViewHelper(_ popViewHelper: PopViewHelper, shouldHidePopView targetView: UIView) {
    
    animateIndicator(false)
  }
}

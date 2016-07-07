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
  
  private var collectionView: UICollectionView!
  private var selectedCountLabel: UILabel!
  private var completionLabel: UILabel!
  private var completionButton: UIControl!
  private var ablumButton: UIControl!
  private var titleLabel: UILabel!
  private var indicatorImageView: UIImageView!
  
  private var imageWidth: CGFloat!
  private var selectItemNum = 0
  private var popViewHelp: PopViewHelper!
  private var ablumView: UIView!
  private var cellFadeAnimation = false
  
  private let thumbIdentifier = "PhotoThumbCell"
  private let previewIdentifier = "CameraPreviewCell"

  private let midSpace: CGFloat = 2
  private let rowCount = 3
  private let ablumButtonWidth: CGFloat = 120
  private let selectedCountLabelWidth: CGFloat = 20
  private let indicatorWidth: CGFloat = 15
  
  var canOpenCamera = true
  var cameraHelper: CameraHelper!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    initView()
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.reloadData()
    
    updateUI()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    imageWidth = (CGRectGetWidth(view.frame) - midSpace * CGFloat(rowCount - 1)) / CGFloat(rowCount)
    
    let scale = UIScreen.mainScreen().scale
    PhotosManager.assetGridThumbnailSize = CGSize(width: imageWidth * scale, height: imageWidth * scale)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func onRadio(cell: PhotoThumbCell) {
    
    let indexPath = collectionView.indexPathForCell(cell)!
    cell.setPhotoSelectedStatusWith(indexPath.row - 1)
    
    updateUI()
  }
  
  func completeButtonClick() {
    
//    PhotosManager.sharedInstance.didFinish()
    collectionView.deleteItemsAtIndexPaths(collectionView.indexPathsForVisibleItems())
    
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
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func goToPhotoBrowser() {
    
    let photoBrowser = PreviewPhotoViewController(delegate: self, quitBlock: { () -> Void in
      self.navigationController?.popViewControllerAnimated(true)
    })
    photoBrowser.delegate = self
    navigationController?.pushViewController(photoBrowser, animated: true)
    
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
   //MARK: - private Implements
  
  private func initView() {
    
    initAblum()
    initNavigationBarButton()
    
    let collectionViewFlowLayout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewFlowLayout)
    collectionView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    collectionView.backgroundColor = UIColor.whiteColor()
    collectionView.registerNib(UINib(nibName: thumbIdentifier, bundle: nil), forCellWithReuseIdentifier: thumbIdentifier)
    collectionView.registerNib(UINib(nibName: previewIdentifier, bundle: nil), forCellWithReuseIdentifier: previewIdentifier)

    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)
    
    initCompletionButton()

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .Plain, target: self, action: #selector(PhotoColletionViewController.onCancel))
    
  }
  
  private func initNavigationBarButton() {
    
    ablumButton = UIControl(frame: CGRect(x: 0 , y: 0, width: ablumButtonWidth, height: 44))
    navigationItem.titleView = ablumButton
    
    ablumButton.addTarget(self, action: #selector(PhotoColletionViewController.albumButtonClick), forControlEvents: .TouchUpInside)
    
    titleLabel = UILabel()
    ablumButton.addSubview(titleLabel)
    titleLabel.snp_makeConstraints { (make) in
      make.center.equalTo(ablumButton)
    }
    
    titleLabel.textColor = UIColor.hexStringToColor("368EFF")
    titleLabel.font = UIFont.systemFontOfSize(18)
    titleLabel.textAlignment = .Center
    
    updateTitle()

    indicatorImageView = UIImageView()
    ablumButton.addSubview(indicatorImageView)
    indicatorImageView.snp_makeConstraints { (make) in
      make.left.equalTo(titleLabel.snp_right).offset(5)
      make.centerY.equalTo(ablumButton)
      make.width.height.equalTo(indicatorWidth)
    }
    
    indicatorImageView.contentMode = .ScaleAspectFit
    indicatorImageView.image = UIImage(named: "ic_down_arrow")
    
  }
  
  private func initAblum() {
  
    ablumView = PhotoAlbumView(frame: view.bounds, delegate: self)
    popViewHelp = PopViewHelper(superView: view, targetView: ablumView, viewPopDirection: .Above, maskStatus: .Normal)
    popViewHelp.showAnimateDuration = 0.35
    popViewHelp.hideAnimateDuration = 0.35
    popViewHelp.alpha = [0, 1, 1]
    popViewHelp.delegate = self
    
  }
  
  private func initCompletionButton() {
  
    completionButton = UIControl(frame: CGRect(x: view.frame.width - 60, y: 0, width: 60, height: 44))
    completionButton.addTarget(self, action: #selector(PhotoColletionViewController.completeButtonClick), forControlEvents: .TouchUpInside)
    navigationController?.navigationBar.addSubview(completionButton)
    
    selectedCountLabel = UILabel(frame: CGRect(x: 0, y: (completionButton.frame.height - selectedCountLabelWidth) / 2, width: selectedCountLabelWidth, height: selectedCountLabelWidth))
    selectedCountLabel.backgroundColor = UIColor.hexStringToColor("03AC00")
    selectedCountLabel.font = UIFont.systemFontOfSize(14)
    selectedCountLabel.textColor = UIColor.whiteColor()
    selectedCountLabel.textAlignment = .Center
    selectedCountLabel.setViewCornerRadius()
    completionButton.addSubview(selectedCountLabel)
    
    completionLabel = UILabel(frame: CGRect(x: selectedCountLabelWidth, y: 0, width: completionButton.frame.width - selectedCountLabelWidth, height: 44))
    completionLabel.textColor = UIColor.hexStringToColor("03AC00")
    completionLabel.text = "完成"
    completionLabel.font = UIFont.systemFontOfSize(14)
    completionLabel.textAlignment = .Center
    completionButton.addSubview(completionLabel)
    
  }
  
  private func checkCamera(){
    
    let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    if (AVAuthorizationStatus.Denied == authStatus || AVAuthorizationStatus.Restricted == authStatus){
      
      let alertController = UIAlertController(title: "相机被禁用", message: "请在设置－隐私－相机中开启", preferredStyle: .Alert)
      let okAction = UIAlertAction(title: "确定", style: .Default, handler: nil)
      alertController.addAction(okAction)
      presentViewController(alertController, animated: true, completion: nil)
    }
  }
  
  private func getPhotoFromCamera(){
    
    if cameraHelper == nil {
      cameraHelper = CameraHelper(handlerViewController: self)
    }
    
    cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Push
    cameraHelper.isCrop = PhotosManager.sharedInstance.isCrop
    cameraHelper.openCamera()
  }
  
  private func updateUI() {
    
    let selectedCount = PhotosManager.sharedInstance.selectedIndexList.count
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.hidden = selectedCount == 0
    selectedCountLabel.text = countString
    
    completionLabel.enabled = selectedCount != 0
    completionButton.enabled = selectedCount != 0
    
  }

  private func updateTitle() {
    
    if let currentAlbumIndex = PhotosManager.sharedInstance.currentAlbumIndex {
      let title = PhotosManager.sharedInstance.getAlbumWith(currentAlbumIndex)?.localizedTitle ?? "相册"
      titleLabel.text = title
      
    }
  }
  
  private func animateIndicator(isIndicatShowing: Bool) {
    
    UIView.animateWithDuration(0.3) { 
      
      let transform = CGAffineTransformMakeRotation(isIndicatShowing ? CGFloat(M_PI) : 0)
      self.indicatorImageView.transform = transform
      
    }
    
  }
}

extension PhotoColletionViewController: UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    var photoNum = PhotosManager.sharedInstance.getImageCountInCurrentAlbum()
    
    if canOpenCamera {
      photoNum += 1
    }
    return photoNum
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let row = indexPath.row
    let showPreview = canOpenCamera && row == 0
    
    let identifier = showPreview ? previewIdentifier : thumbIdentifier
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    
    if !showPreview {
      
      let thumbCell = cell as! PhotoThumbCell
      thumbCell.onRadio = onRadio
      thumbCell.setImageWith(canOpenCamera == true ? indexPath.row - 1 : indexPath.row)
      
    }
    
    return cell
  }
}

extension PhotoColletionViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return CGSize(width: imageWidth, height: imageWidth)
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
    return midSpace
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
    return midSpace
  }
}

extension PhotoColletionViewController: UICollectionViewDelegate {
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
    let row = indexPath.row
    
    if canOpenCamera && row == 0 {
      
      getPhotoFromCamera()
      
    } else {
      
      if PhotosManager.sharedInstance.isCrop {
        
        self.navigationController?.pushViewController(PhotoCropViewController(imageIndex: canOpenCamera == true ? indexPath.row - 1 : indexPath.row), animated: true)
        
      } else {
        
        selectItemNum = canOpenCamera == true ? indexPath.row - 1 : indexPath.row
        goToPhotoBrowser()
        
      }
      
    }
  }
}

extension PhotoColletionViewController: PhotoAlbumViewDelegate {
  
  func photoAlbumView(photoAlbumView: PhotoAlbumView, didSelectAtIndex index: Int) {
    updateTitle()
    popViewHelp.hidePopView()
    collectionView.reloadData()
    cellFadeAnimation = true


  }
  
  func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

    guard cellFadeAnimation else { return }
    
    cell.alpha = 0
    
    UIView.animateWithDuration(0.3, animations: { 
      
      cell.alpha = 1

      }) { finish in
        
      self.cellFadeAnimation = false

    }

  }
  
}

extension PhotoColletionViewController: WZPhotoBrowserLiteDelegate {
  
  func numberOfImage(photoBrowser: WZPhotoBrowserLite) -> Int {
    
    return PhotosManager.sharedInstance.getImageCountInCurrentAlbum()
    
  }
  
  func firstDisplayIndex(photoBrowser: WZPhotoBrowserLite) -> Int {
    
    return selectItemNum
  }
}

extension PhotoColletionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    
    let type : String = info[UIImagePickerControllerMediaType] as! String
    
    if type == "public.image" {
      
      let image : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
      
      if PhotosManager.sharedInstance.isCrop {
        
        picker.dismissViewControllerAnimated(false, completion: nil)
        
        navigationController?.pushViewController(PhotoCropViewController(image: image), animated: true)
        
      } else {
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        PhotosManager.sharedInstance.didFinish(image)
        
      }
    }
  }
}

extension PhotoColletionViewController: PopViewHelperDelegate {
  
  func popViewHelper(popViewHelper: PopViewHelper, shouldShowPopView targetView: UIView) {
    
    animateIndicator(true)
  }
  
  func popViewHelper(popViewHelper: PopViewHelper, shouldHidePopView targetView: UIView) {
    
    animateIndicator(false)
  }
  
}
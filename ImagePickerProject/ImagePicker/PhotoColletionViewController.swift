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
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var selectedCountLabel: UILabel!
  @IBOutlet weak var completionButton: UIButton!
  @IBOutlet weak var previewButton: UIButton!
  
  private var fetchResult: PHFetchResult!
  private var manager: PHCachingImageManager!
  private var imageWidth: CGFloat!
  private var selectItemNum = 0
  
  private let identifier = "PhotoThumbCell"
  private let midSpace: CGFloat = 2
  private let rowCount = 4
  
  var canOpenCamera = true
  var cameraHelper: CameraHelper!
  
  override func loadView() {
    super.loadView()
    
    let nib = UINib(nibName: "PhotoColletionViewController", bundle: nil)
    nib.instantiateWithOwner(self, options: nil)
  }
  
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
  
  @IBAction func onPreview() {
    
    if PhotosManager.sharedInstance.selectedIndexList.count > 0 {
      
      selectItemNum = PhotosManager.sharedInstance.selectedIndexList.sort({$0 > $1})[0]
      
    } else {
      
      return
      
    }
    
    goToPhotoBrowser()
  }
  
  @IBAction func onComplete() {
    
    PhotosManager.sharedInstance.didFinish()
    
  }
  
  func onCancel() {
    
    PhotosManager.sharedInstance.cancel()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
   //MARK: - private Implements
  
  func initView() {
    
    if let currentAlbumIndex = PhotosManager.sharedInstance.currentAlbumIndex {
      title = PhotosManager.sharedInstance.getAlbumWith(currentAlbumIndex)?.localizedTitle ?? "相册"
    }
    
    collectionView.backgroundColor = UIColor.blackColor()
    collectionView.registerNib(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)
    
    selectedCountLabel.setViewCornerRadius()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .Plain, target: self, action: "onCancel")
    
  }
  
  private func checkCamera(){
    
    let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    if (AVAuthorizationStatus.Denied == authStatus || AVAuthorizationStatus.Restricted == authStatus){
      
      let _ = UIAlertView(title: "相机被禁用", message: "请在设置－隐私－相机中开启", delegate: nil, cancelButtonTitle: "确定").show()
      
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
    
    completionButton.enabled = selectedCount != 0
    previewButton.enabled = selectedCount != 0
    
  }
  
  func goToPhotoBrowser() {
    
    let photoBrowser = PreviewPhotoViewController(delegate: self, quitBlock: { () -> Void in
      self.navigationController?.popViewControllerAnimated(true)
    })
    photoBrowser.delegate = self
    navigationController?.pushViewController(photoBrowser, animated: true)
    
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
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PhotoThumbCell
    
    let row = indexPath.row
    
    if canOpenCamera && row == 0 {
      
      cell.setAsCamera()
      
    } else {
      
      cell.onRadio = onRadio
      cell.setImageWith(canOpenCamera == true ? indexPath.row - 1 : indexPath.row)
      
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

extension PhotoColletionViewController: WZPhotoBrowserDelegate {
  
  func numberOfImage(photoBrowser: WZPhotoBrowser) -> Int {
    
    return PhotosManager.sharedInstance.getImageCountInCurrentAlbum()
    
  }
  
  func firstDisplayIndex(photoBrowser: WZPhotoBrowser) -> Int {
    
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
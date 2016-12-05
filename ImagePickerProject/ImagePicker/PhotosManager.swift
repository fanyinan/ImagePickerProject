//
//  AssetsManager.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import Photos

enum PhotoSizeType {
  case thumbnail
  case preview
  case origin
}

struct ImageRectScale {
  
  var xScale: CGFloat
  var yScale: CGFloat
  var widthScale: CGFloat
  var heighScale: CGFloat
  
}

class PhotosManager: NSObject {
  
  static let sharedInstance = PhotosManager()
  static var assetGridThumbnailSize = CGSize(width: 80, height: 80)
  static var assetPreviewImageSize = UIScreen.main.bounds.size
  
  fileprivate var assetCollectionList: [PHAssetCollection] = []
  fileprivate var imageManager: PHImageManager!
  fileprivate var currentImageFetchResult: PHFetchResult<AnyObject>!
  fileprivate(set) var selectedIndexList: [Int] = []
  
  var maxSelectedCount: Int = 1 {
    didSet {
      
      if maxSelectedCount <= 0 {
        maxSelectedCount = 1
      }
      
      if maxSelectedCount > 1 {
        isCrop = false
      }
    }
  }
  var currentAlbumIndex: Int? {
    didSet{
      
      guard let _currentAlbumIndex = currentAlbumIndex else { return }
      
      let assetCollection = getAlbumWith(_currentAlbumIndex)
      currentImageFetchResult = getImageFetchResultWith(assetCollection!)
    }
  }
  
  //裁剪图片用的比例
  var rectScale: ImageRectScale?
  //是否裁剪
  var isCrop: Bool = false {
    didSet{
      
      //只有当最大图片数量为1时才可以裁剪
      if maxSelectedCount != 1 {
        isCrop = false
      }
    }
  }
  
  /*之前使用notification来通知选择照片完成，但是如果notification没有被remove掉的话会被多次接收多次通知
  *所以改用这种方式
  */
  weak var imagePicker: ImagePickerHelper?
  
  override init() {
    
    super.init()
    
    imageManager = PHImageManager()
    
    PHPhotoLibrary.shared().register(self)
  }
  
  //startphoto是调用，保存当前imagePicker
  func prepareWith(_ imagePicker: ImagePickerHelper) {
    
    self.imagePicker = imagePicker
    
  }
  
  //onCompletion是调用，重置数据
  func didFinish(_ image: UIImage? = nil) {
    
    imagePicker?.onComplete(image)
    
    imagePicker = nil
    
    isCrop = false
    rectScale = nil
    
    maxSelectedCount = 1
    
  }
  
  //未选择图片但dismiss时调用，重置数据
  func cancel() {
    
    isCrop = false
    rectScale = nil
    
    maxSelectedCount = 1
    
  }
  
  fileprivate func getPhotoAlbum() -> [PHAssetCollection] {
    
    if assetCollectionList.isEmpty {
      
      var albumType: [PHAssetCollectionSubtype] = [.smartAlbumRecentlyAdded, .smartAlbumUserLibrary]
      
      if #available(iOS 9.0, *) {
        albumType += [.smartAlbumSelfPortraits, .smartAlbumScreenshots]
      } else {
        // Fallback on earlier versions
      }
      
      //      ["相机胶卷", "自拍" , "最近添加", "屏幕快照"]
      let defaultAlbum = PHAssetCollectionSubtype.smartAlbumUserLibrary
      
      let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
      
      albumFetchResult.enumerateObjects({ (object, index, point) -> Void in
        
        let assetCollection = object 
        
        let title = assetCollection.localizedTitle
        
        if title != nil && albumType.contains(assetCollection.assetCollectionSubtype) {
          self.assetCollectionList += [assetCollection]
        }
        
        if assetCollection.assetCollectionSubtype == defaultAlbum {
          self.currentAlbumIndex = self.assetCollectionList.count - 1
        }
        
      })
      
    }
    
    return assetCollectionList
  }
  
  func getAlbumWith(_ index: Int) -> PHAssetCollection? {
    
    guard getAlbumCount() > index else {
      
      return nil
    }
    
    return getPhotoAlbum()[index]
  }
  
  func getAlbumCount() -> Int {
    return getPhotoAlbum().count
  }
  
  //通过相册获取照片集合
  func getImageFetchResultWith(_ album: PHAssetCollection) -> PHFetchResult<AnyObject> {
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    let imageFetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
    
    return imageFetchResult as! PHFetchResult<AnyObject>
  }
  
  func getImageCountInCurrentAlbum() -> Int {
    
    guard currentAlbumIndex != nil else {
      print("currentAlbumIndex is nil")
      return 0
    }
    
    return currentImageFetchResult.count
  }
  
  func getImageInCurrentAlbumWith(_ index: Int, withSizeType sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?) -> Void) {
    
    guard let _currentAlbumIndex = currentAlbumIndex else {
      print("currentAlbumIndex is nil")
      handleCompletion(nil)
      return
    }
    
    getImageWith(_currentAlbumIndex, withIndex: index, withSizeType: sizeType) { (image) -> Void in
      
      let imageCroped = self.cropImage(image)
      
      handleCompletion(imageCroped)
      
    }
  }
  
  func getImageWith(_ albumIndex: Int, withIndex index: Int, withSizeType sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?) -> Void) {
    
    if currentAlbumIndex != albumIndex {
      currentAlbumIndex = albumIndex
    }
    
    if getAlbumCount() <= albumIndex {
      handleCompletion(nil)
      return
    }
    
    if currentImageFetchResult.count <= index {
      handleCompletion(nil)
      return
    }
    
    let asset = currentImageFetchResult[index] as! PHAsset
    
    var imageSize = CGSize.zero
    let imageRequestOptions = PHImageRequestOptions()
    
    switch sizeType {
    case .thumbnail:
      imageSize = PhotosManager.assetGridThumbnailSize
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .fast
      imageRequestOptions.isNetworkAccessAllowed = false

    case .preview:
      imageSize = PhotosManager.assetPreviewImageSize
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .fast
      imageRequestOptions.isNetworkAccessAllowed = true

    case .origin:
      imageSize = PHImageManagerMaximumSize
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .none
      imageRequestOptions.deliveryMode = .highQualityFormat
      imageRequestOptions.isNetworkAccessAllowed = true

    }
    
    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: imageRequestOptions) { (image: UIImage?, _) -> Void in
      handleCompletion(image)
    }
  }
  
  
  /**
   选择图片或取消选择图片
   
   - parameter index: 照片index
   
   - returns: 是否成功，如果不成功，则以达到最大数量
   */
  func selectPhotoWith(_ index: Int) -> Bool {
    
    let isExist = getPhotoSelectedStatus(index)
    
    if isExist {
      selectedIndexList = selectedIndexList.filter({$0 != index})
    } else {
      
      if maxSelectedCount == selectedIndexList.count {
        
        return false
        
      } else {
        
        selectedIndexList += [index]
        return true
        
      }
    }
    
    return true
  }
  
  /**
   获取该照片的选中状态
   
   - parameter index: 照片index
   
   - returns: true为已被选中，false为未选中
   */
  func getPhotoSelectedStatus(_ index: Int) -> Bool {
    return !selectedIndexList.filter({$0 == index}).isEmpty
  }
  
  func clearData() {
    
    rectScale = nil
    selectedIndexList.removeAll()
    
  }
  
  func fetchSelectedImages(_ handleCompletion: @escaping (_ images: [UIImage]) -> Void) {
    
    selectedIndexList = selectedIndexList.sorted(by: {$0 < $1})
    getAllSelectedImageInCurrentAlbumWith(selectedIndexList, imageList: [], handleCompletion: handleCompletion)
    
  }
  
  func getAllSelectedImageInCurrentAlbumWith(_ imageIndexList: [Int], imageList: [UIImage],  handleCompletion: @escaping (_ images: [UIImage]) -> Void) {
    
    if imageIndexList.count == 0 {
      handleCompletion(imageList)
      return
    }
    
    getImageInCurrentAlbumWith(imageIndexList[0], withSizeType: .origin) { (image: UIImage?) -> Void in
      
      if image == nil {
        
        handleCompletion([])
        return
      }
      
      self.getAllSelectedImageInCurrentAlbumWith(Array(imageIndexList[1..<imageIndexList.count]), imageList: imageList + [image!], handleCompletion: handleCompletion)
    }
  }
  
  func cropImage(_ originImage: UIImage?) -> UIImage? {
    
    guard isCrop else { return originImage }
    
    guard let _rectScale = rectScale else {
      return originImage
    }
    
    guard let _originImage = originImage else {
      return originImage
    }
    
    let cropRect = CGRect(x: _originImage.size.width * _rectScale.xScale, y: _originImage.size.height * _rectScale.yScale, width: _originImage.size.width * _rectScale.widthScale, height: _originImage.size.width * _rectScale.heighScale)
    
    let orientationRect = transformOrientationRect(_originImage, rect: cropRect)
    
    let cropImageRef = _originImage.cgImage?.cropping(to: orientationRect)
    
    guard let _cropImageRef = cropImageRef else { return nil }
    
    let cropImage = UIImage(cgImage: _cropImageRef, scale: 1, orientation: _originImage.imageOrientation)
    
    return cropImage
    
  }
  
  //旋转rect
  fileprivate func transformOrientationRect(_ originImage: UIImage, rect: CGRect) -> CGRect {
    
    var rectTransform: CGAffineTransform = CGAffineTransform.identity
    
    switch originImage.imageOrientation {
    case .left:
      rectTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2)).translatedBy(x: 0, y: -originImage.size.height)
    case .right:
      rectTransform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2)).translatedBy(x: -originImage.size.width, y: 0)
    case .down:
      rectTransform = CGAffineTransform(rotationAngle: CGFloat(-M_PI)).translatedBy(x: -originImage.size.width, y: -originImage.size.height)
    default:
      break
    }
    
    let orientationRect = rect.applying(rectTransform.scaledBy(x: originImage.scale, y: originImage.scale))
    
    return orientationRect
    
  }
}

extension PhotosManager: PHPhotoLibraryChangeObserver {
  
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    
    getPhotoAlbum()
    
  }
}

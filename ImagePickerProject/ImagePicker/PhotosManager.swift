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
  static var assetGridThumbnailSize = CGSize(width: 50, height: 50)
  static var assetPreviewImageSize = UIScreen.main.bounds.size
  
  private var assetCollectionList: [PHAssetCollection] = []
  private var imageManager: PHCachingImageManager!
  private var currentImageFetchResult: PHFetchResult<AnyObject>!
  private(set) var selectedIndexList: [Int] = []
  private var photoKeysInCache: Set<String> = []
  
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
      
      guard let assetCollection = getAlbumWith(_currentAlbumIndex) else { return }
      currentImageFetchResult = getImageFetchResultWith(assetCollection)
    }
  }
  
  //裁剪图片用的比例
  var rectScale: ImageRectScale?
  //是否裁剪
  var isCrop: Bool = false {
    didSet{
      
      //只有当最大图片数量为1时才可以裁剪
      if maxSelectedCount != 1 && isCrop {
        isCrop = false
      }
    }
  }
  
  var resourceOption
  /*之前使用notification来通知选择照片完成，但是如果notification没有被remove掉的话会被多次接收多次通知
   *所以改用这种方式
   */
  weak var imagePicker: ImagePickerHelper?
  
  override init() {
    
    super.init()
    
    imageManager = PHCachingImageManager()
    imageManager.allowsCachingHighQualityImages = false
    
    PHPhotoLibrary.shared().register(self)
    
  }
  
  //startphoto是调用，保存当前imagePicker
  func prepareWith(_ imagePicker: ImagePickerHelper) {
    
    self.imagePicker = imagePicker
    
  }
  
  //onCompletion是调用，重置数据
  func didFinish(_ image: UIImage? = nil) {
    
    imagePicker?.onComplete(image)
        
  }
  
  //未选择图片但dismiss时调用，重置数据
  func cancel() {
    
    clearData()
    
  }
  
  fileprivate func getPhotoAlbum() -> [PHAssetCollection] {
    
    guard assetCollectionList.isEmpty else {
      
      return assetCollectionList
    }
    
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
    
    if self.currentAlbumIndex == nil && assetCollectionList.count > 0 {
      self.currentAlbumIndex = 0
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
  
  func getImageInCurrentAlbumWith(_ index: Int, withSizeType sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void, handleImageRequestID: ((_ imageRquestID: Int32) -> Void)? = nil ){
    
    guard let _currentAlbumIndex = currentAlbumIndex else {
      print("currentAlbumIndex is nil")
      handleCompletion(nil, false)
      return
    }
    
    
    if sizeType == .thumbnail {
      
      if let image = SDImageCache.shared().imageFromMemoryCache(forKey: "localAssert_\(_currentAlbumIndex)_\(index)") {
        
        handleCompletion(image, false)
        
        return
      }
    }
    
    DispatchQueue.global().async {
      
      let imageRequestID = self.getImageWith(_currentAlbumIndex, withIndex: index, withSizeType: sizeType) { (image, isInICloud) -> Void in
        
        let image = sizeType == .origin ? self.cropImage(image) : image
        
        let key = "localAssert_\(_currentAlbumIndex)_\(index)"
        self.photoKeysInCache.insert(key)
        SDImageCache.shared().store(image, forKey: key, toDisk: false)
        
        DispatchQueue.main.async {
          
          handleCompletion(image, isInICloud)
          
        }
      }
      
      DispatchQueue.main.async  {
        handleImageRequestID?(imageRequestID)
      }
    }
  }
  
  func checkImageIsInICloud(with index: Int, completion: @escaping ((Bool) -> Void)) {
  
    guard let _currentAlbumIndex = currentAlbumIndex else {
      print("currentAlbumIndex is nil")
      completion(false)
      return
    }
    
    getImageWith(_currentAlbumIndex, withIndex: index, withSizeType: .origin) { (_, isInICloud) -> Void in
    
      if isInICloud {
        print("该图片尚未从iCloud下载\n请使用本地图片")
      }
      
      completion(isInICloud)
    }
  }
  
  @discardableResult
  func getImageWith(_ albumIndex: Int, withIndex index: Int, withSizeType sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void) -> PHImageRequestID {
    
    if currentAlbumIndex != albumIndex {
      currentAlbumIndex = albumIndex
    }
    
    if getAlbumCount() <= albumIndex {
      handleCompletion(nil, false)
      return 0
    }
    
    if currentImageFetchResult.count <= index {
      handleCompletion(nil, false)
      return 0
    }
    
    let asset = currentImageFetchResult[index] as! PHAsset
    
    var imageSize = CGSize.zero
    let imageRequestOptions = PHImageRequestOptions()
    
    switch sizeType {
    case .thumbnail:
      imageSize = PhotosManager.assetGridThumbnailSize
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .fast
      imageRequestOptions.deliveryMode = .opportunistic
      imageRequestOptions.isNetworkAccessAllowed = true
      
    case .preview:
      imageSize = PhotosManager.assetPreviewImageSize
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .fast
      imageRequestOptions.deliveryMode = .highQualityFormat
      imageRequestOptions.isNetworkAccessAllowed = false
      
    case .origin:
      imageSize = PHImageManagerMaximumSize
      imageRequestOptions.isSynchronous = true
      imageRequestOptions.resizeMode = .none
      imageRequestOptions.deliveryMode = .highQualityFormat
      imageRequestOptions.isNetworkAccessAllowed = false

    }
    
    let imageRequestID = imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: imageRequestOptions) { (image: UIImage?, info) -> Void in
      
      handleCompletion(image, info?[PHImageResultIsInCloudKey] as? Bool ?? false)
    }
    
    return imageRequestID
  }
  
  func cancelRequestImage(with imageRequestID: Int32) {
    imageManager.cancelImageRequest(imageRequestID)
  }
  
  /**
   选择图片或取消选择图片
   
   - parameter index: 照片index
   
   - returns: 是否成功，如果不成功，则以达到最大数量
   */
  
  @discardableResult
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
    return selectedIndexList.contains(index)
  }
  
  func clearData() {
    
    imagePicker = nil

    isCrop = false
    maxSelectedCount = 1
    rectScale = nil
    selectedIndexList.removeAll()
    
    for photoKey in photoKeysInCache {
      
      SDImageCache.shared().removeImage(forKey: photoKey)
      
    }
    
    photoKeysInCache.removeAll()
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
    
    getImageInCurrentAlbumWith(imageIndexList[0], withSizeType: .origin, handleCompletion: { (image: UIImage?, _) -> Void in
      
      if image == nil {
        
        handleCompletion([])
        return
      }
      
      self.getAllSelectedImageInCurrentAlbumWith(Array(imageIndexList[1..<imageIndexList.count]), imageList: imageList + [image!], handleCompletion: handleCompletion)
      
    }, handleImageRequestID: nil)
    
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
    
    let orientationRect = _originImage.transformOrientationRect(cropRect)
    
    let cropImageRef = _originImage.cgImage?.cropping(to: orientationRect)
    
    guard let _cropImageRef = cropImageRef else { return nil }
    
    let cropImage = UIImage(cgImage: _cropImageRef, scale: 1, orientation: _originImage.imageOrientation)
    
    return cropImage
    
  }
}

extension PhotosManager: PHPhotoLibraryChangeObserver {
  
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    
    _ = getPhotoAlbum()
    
  }
}

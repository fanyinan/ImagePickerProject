//
//  AssetsManager.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import Photos

enum PhotoSizeType {
  case Thumbnail
  case Preview
  case Origin
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
  static var assetPreviewImageSize = UIScreen.mainScreen().bounds.size
  
  private var assetCollectionList: [PHAssetCollection] = []
  private var imageManager: PHImageManager!
  private var currentImageFetchResult: PHFetchResult!
  private(set) var selectedIndexList: [Int] = []
  
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
    
    PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
  }
  
  //startphoto是调用，保存当前imagePicker
  func prepareWith(imagePicker: ImagePickerHelper) {
    
    self.imagePicker = imagePicker
    
  }
  
  //onCompletion是调用，重置数据
  func didFinish(image: UIImage? = nil) {
    
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
  
  private func getPhotoAlbum() -> [PHAssetCollection] {
    
    if assetCollectionList.isEmpty {
      
      var albumType: [PHAssetCollectionSubtype] = [.SmartAlbumRecentlyAdded, .SmartAlbumUserLibrary]
      
      if #available(iOS 9.0, *) {
        albumType += [.SmartAlbumSelfPortraits, .SmartAlbumScreenshots]
      } else {
        // Fallback on earlier versions
      }
      
      //      ["相机胶卷", "自拍" , "最近添加", "屏幕快照"]
      let defaultAlbum = PHAssetCollectionSubtype.SmartAlbumUserLibrary
      
      let albumFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
      
      albumFetchResult.enumerateObjectsUsingBlock({ (object, index, point) -> Void in
        
        let assetCollection = object as! PHAssetCollection
        
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
  
  func getAlbumWith(index: Int) -> PHAssetCollection? {
    
    guard getAlbumCount() > index else {
      
      return nil
    }
    
    return getPhotoAlbum()[index]
  }
  
  func getAlbumCount() -> Int {
    return getPhotoAlbum().count
  }
  
  //通过相册获取照片集合
  func getImageFetchResultWith(album: PHAssetCollection) -> PHFetchResult {
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
    let imageFetchResult = PHAsset.fetchAssetsInAssetCollection(album, options: fetchOptions)
    
    return imageFetchResult
  }
  
  func getImageCountInCurrentAlbum() -> Int {
    
    guard currentAlbumIndex != nil else {
      print("currentAlbumIndex is nil")
      return 0
    }
    
    return currentImageFetchResult.count
  }
  
  func getImageInCurrentAlbumWith(index: Int, withSizeType sizeType: PhotoSizeType, handleCompletion: (image: UIImage?) -> Void) {
    
    guard let _currentAlbumIndex = currentAlbumIndex else {
      print("currentAlbumIndex is nil")
      handleCompletion(image: nil)
      return
    }
    
    getImageWith(_currentAlbumIndex, withIndex: index, withSizeType: sizeType) { (image) -> Void in
      
      let imageCroped = self.cropImage(image)
      
      handleCompletion(image: imageCroped)
      
    }
  }
  
  func getImageWith(albumIndex: Int, withIndex index: Int, withSizeType sizeType: PhotoSizeType, handleCompletion: (image: UIImage?) -> Void) {
    
    if currentAlbumIndex != albumIndex {
      currentAlbumIndex = albumIndex
    }
    
    if getAlbumCount() <= albumIndex {
      handleCompletion(image: nil)
      return
    }
    
    if currentImageFetchResult.count <= index {
      handleCompletion(image: nil)
      return
    }
    
    let asset = currentImageFetchResult[index] as! PHAsset
    
    var imageSize = CGSizeZero
    let imageRequestOptions = PHImageRequestOptions()
    imageRequestOptions.networkAccessAllowed = false
    
    switch sizeType {
    case .Thumbnail:
      imageSize = PhotosManager.assetGridThumbnailSize
      imageRequestOptions.synchronous = false
      imageRequestOptions.resizeMode = .Fast
      
    case .Preview:
      imageSize = PhotosManager.assetPreviewImageSize
      imageRequestOptions.synchronous = true
      imageRequestOptions.resizeMode = .Fast
      
    case .Origin:
      imageSize = PHImageManagerMaximumSize
      imageRequestOptions.synchronous = true
      imageRequestOptions.resizeMode = .None
      
    }
    
    imageManager.requestImageForAsset(asset, targetSize: imageSize, contentMode: .AspectFill, options: imageRequestOptions) { (image: UIImage?, _) -> Void in
      handleCompletion(image: image)
    }
  }
  
  
  /**
   选择图片或取消选择图片
   
   - parameter index: 照片index
   
   - returns: 是否成功，如果不成功，则以达到最大数量
   */
  func selectPhotoWith(index: Int) -> Bool {
    
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
  func getPhotoSelectedStatus(index: Int) -> Bool {
    return !selectedIndexList.filter({$0 == index}).isEmpty
  }
  
  func clearData() {
    
    rectScale = nil
    selectedIndexList.removeAll()
    
  }
  
  func fetchSelectedImages(handleCompletion: (images: [UIImage]) -> Void) {
    
    selectedIndexList = selectedIndexList.sort({$0 < $1})
    getAllSelectedImageInCurrentAlbumWith(selectedIndexList, imageList: [], handleCompletion: handleCompletion)
    
  }
  
  func getAllSelectedImageInCurrentAlbumWith(imageIndexList: [Int], imageList: [UIImage],  handleCompletion: (images: [UIImage]) -> Void) {
    
    if imageIndexList.count == 0 {
      handleCompletion(images: imageList)
      return
    }
    
    getImageInCurrentAlbumWith(imageIndexList[0], withSizeType: .Origin) { (image: UIImage?) -> Void in
      
      if image == nil {
        
        handleCompletion(images: [])
        return
      }
      
      self.getAllSelectedImageInCurrentAlbumWith(Array(imageIndexList[1..<imageIndexList.count]), imageList: imageList + [image!], handleCompletion: handleCompletion)
    }
  }
  
  func cropImage(originImage: UIImage?) -> UIImage? {
    
    guard isCrop else { return originImage }
    
    guard let _rectScale = rectScale else {
      return originImage
    }
    
    guard let _originImage = originImage else {
      return originImage
    }
    
    let cropRect = CGRect(x: _originImage.size.width * _rectScale.xScale, y: _originImage.size.height * _rectScale.yScale, width: _originImage.size.width * _rectScale.widthScale, height: _originImage.size.width * _rectScale.heighScale)
    
    let orientationRect = transformOrientationRect(_originImage, rect: cropRect)
    
    let cropImageRef = CGImageCreateWithImageInRect(_originImage.CGImage, orientationRect)
    
    guard let _cropImageRef = cropImageRef else { return nil }
    
    let cropImage = UIImage(CGImage: _cropImageRef, scale: 1, orientation: _originImage.imageOrientation)
    
    return cropImage
    
  }
  
  //旋转rect
  private func transformOrientationRect(originImage: UIImage, rect: CGRect) -> CGRect {
    
    var rectTransform: CGAffineTransform = CGAffineTransformIdentity
    
    switch originImage.imageOrientation {
    case .Left:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(M_PI_2)), 0, -originImage.size.height)
    case .Right:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(-M_PI_2)), -originImage.size.width, 0)
    case .Down:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(-M_PI)), -originImage.size.width, -originImage.size.height)
    default:
      break
    }
    
    let orientationRect = CGRectApplyAffineTransform(rect, CGAffineTransformScale(rectTransform, originImage.scale, originImage.scale))
    
    return orientationRect
    
  }
}

extension PhotosManager: PHPhotoLibraryChangeObserver {
  
  func photoLibraryDidChange(changeInstance: PHChange) {
    
    getPhotoAlbum()
    
  }
}
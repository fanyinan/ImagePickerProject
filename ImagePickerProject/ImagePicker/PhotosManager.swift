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
  case export
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
  static var assetExportImageSize = UIScreen.main.bounds.size

  private var assetCollectionList: [PHAssetCollection] = []
  private var imageManager: PHCachingImageManager!
  private var currentAlbumFetchResult: PHFetchResult<PHAsset>!
  private(set) var currentImageAlbumFetchResult: PHFetchResult<PHAsset>!
  private(set) var selectedImages: Set<PHAsset> = []
  private(set) var selectedVideo: PHAsset?
  
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
      currentAlbumFetchResult = getFetchResult(with: assetCollection, resourceOption: resourceOption)
      currentImageAlbumFetchResult = getFetchResult(with: assetCollection, resourceOption: [.image])
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
  
  var resourceOption: ResourceOption = .image
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
  func getFetchResult(with album: PHAssetCollection, resourceOption: ResourceOption) -> PHFetchResult<PHAsset> {
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    
    if resourceOption.contains(.image) && !resourceOption.contains(.video){
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    }
    
    if !resourceOption.contains(.image) && resourceOption.contains(.video) {
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
    }
    
    if resourceOption.contains(.image) && resourceOption.contains(.video) {
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
    }
    
    let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
    
    return fetchResult
  }
  
  func getImageCountInCurrentAlbum() -> Int {
    
    guard currentAlbumIndex != nil else {
      print("currentAlbumIndex is nil")
      return 0
    }
    
    return currentAlbumFetchResult.count
  }
  
  func getAssetInCurrentAlbum(with index: Int) -> PHAsset? {
    
    guard currentAlbumFetchResult.count > index else {
      return nil
    }
    let asset = currentAlbumFetchResult[index]
    return asset
  }
  
  func fetchImage(with asset: PHAsset, sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void) {
    
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
      
    case .export:
      imageSize = PHImageManagerMaximumSize
      imageRequestOptions.isSynchronous = true
      imageRequestOptions.resizeMode = .none
      imageRequestOptions.deliveryMode = .highQualityFormat
      imageRequestOptions.isNetworkAccessAllowed = false
      
    }
    
    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: imageRequestOptions) { (image: UIImage?, info) -> Void in
      
      handleCompletion(image, info?[PHImageResultIsInCloudKey] as? Bool ?? false)
    }
  }
  
  func fetchImage(with albumIndex: Int, imageIndex: Int, sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void) {
    
    if currentAlbumIndex != albumIndex {
      currentAlbumIndex = albumIndex
    }
    
    if getAlbumCount() <= albumIndex {
      handleCompletion(nil, false)
    }
    
    if currentAlbumFetchResult.count <= imageIndex {
      handleCompletion(nil, false)
    }
    
    guard let asset = getAssetInCurrentAlbum(with: imageIndex) else {
      handleCompletion(nil, false)
      return
    }
    
    fetchImage(with: asset, sizeType: sizeType, handleCompletion: handleCompletion)
    
  }
  
  func checkImageIsInICloud(with asset: PHAsset, completion: @escaping ((Bool) -> Void)) {
    
    fetchImage(with: asset, sizeType: .export) { (_, isInICloud) -> Void in
    
      if isInICloud {
        print("该图片尚未从iCloud下载\n请使用本地图片")
      }
      
      completion(isInICloud)
    }
  }
  
  /**
   选择图片或取消选择图片
   
   - parameter index: 照片index
   
   - returns: 是否成功，如果不成功，则以达到最大数量
   */
  
  @discardableResult
  func selectPhoto(with asset: PHAsset) -> Bool {
    
    let isExist = getPhotoSelectedStatus(with: asset)
    
    if isExist {
      selectedImages.remove(asset)
    } else {
      
      if maxSelectedCount == selectedImages.count {
        
        return false
        
      } else {
        
        selectedImages.insert(asset)
        return true
        
      }
    }
    
    return true
  }
  
  @discardableResult
  func selectVideo(with asset: PHAsset) -> Bool {
    
    guard let videoIndex = selectedVideo else {
      selectedVideo = asset
      return true
    }
    
    selectedVideo = videoIndex == asset ? nil : asset
    
    return selectedVideo != nil
  }
  
  /**
   获取该照片的选中状态
   
   - parameter index: 照片index
   
   - returns: true为已被选中，false为未选中
   */
  func getPhotoSelectedStatus(with asset: PHAsset) -> Bool {
    return selectedImages.contains(asset)
  }
  
  func clearData() {
    
    imagePicker = nil

    isCrop = false
    maxSelectedCount = 1
    rectScale = nil
    selectedImages.removeAll()
    resourceOption = .image
 
  }
  
  func removeSelectionIfMaxCountIsOne() {
    if maxSelectedCount == 1 {
      selectedImages.removeAll()
    }
    selectedVideo = nil
  }
  
  func fetchSelectedImages(_ handleCompletion: @escaping (_ images: [UIImage]) -> Void) {
    
    let imageAssets = Array(selectedImages).sorted(by: {$0.creationDate ?? Date() < $1.creationDate ?? Date()})
    getAllSelectedImageInCurrentAlbum(with: imageAssets, imageList: [], handleCompletion: handleCompletion)
    
  }
  
  func getAllSelectedImageInCurrentAlbum(with imageAssets: [PHAsset], imageList: [UIImage],  handleCompletion: @escaping (_ images: [UIImage]) -> Void) {
    
    if imageAssets.count == 0 {
      handleCompletion(imageList)
      return
    }
    
    fetchImage(with: imageAssets[0], sizeType: .export) { (image: UIImage?, _) -> Void in
      if image == nil {
        
        handleCompletion([])
        return
      }
      
      self.getAllSelectedImageInCurrentAlbum(with: Array(imageAssets[1..<imageAssets.count]), imageList: imageList + [image!], handleCompletion: handleCompletion)
      
    }
  }
  
  func fetchVideo(handleCompletion: @escaping (_ avAsset: AVAsset?) -> Void) {
    
    guard let selectedVideo = selectedVideo else { return }
    
    let videoRequestOptions = PHVideoRequestOptions()
    videoRequestOptions.isNetworkAccessAllowed = false
    videoRequestOptions.deliveryMode = .fastFormat
    
    imageManager.requestAVAsset(forVideo: selectedVideo, options: videoRequestOptions) { (avAsset, _, _) in
      handleCompletion(avAsset)
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

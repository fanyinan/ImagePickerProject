//
//  PhotoAlbumView.swift
//  ImagePickerProject
//
//  Created by 范祎楠 on 16/7/6.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

protocol PhotoAlbumViewDelegate: NSObjectProtocol {
  
  func photoAlbumView(photoAlbumView: PhotoAlbumView, didSelectAtIndex index: Int)
  
}

class PhotoAlbumView: UIView {

  private var tableView: UITableView!
  private var delegate: PhotoAlbumViewDelegate
  
  let identifier = "PhotoAlbumCell"
  
  init(frame: CGRect, delegate: PhotoAlbumViewDelegate) {
    
    self.delegate = delegate
    
    super.init(frame: frame)
    
    initView()

  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
//    PhotosManager.sharedInstance.clearData()
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
  //MARK: - private Implements
  
  func initView(){
    
    backgroundColor = UIColor.greenColor()
    
    tableView = UITableView(frame: bounds, style: .Plain)
    tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    tableView.backgroundColor = UIColor.whiteColor()
    tableView.tableFooterView = UIView()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.setNibCell(identifier)
    tableView.setSeparatorByEdge()
    tableView.separatorColor = separatorColor
    tableView.rowHeight = 60.0
    addSubview(tableView)
    
    tableView.reloadData()
    
  }
  
}

extension PhotoAlbumView: UITableViewDataSource {
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return PhotosManager.sharedInstance.getAlbumCount()
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! PhotoAlbumCell
    
    guard let collection = PhotosManager.sharedInstance.getAlbumWith(indexPath.row) else  { return cell }
    
    cell.titleLabel.text = "\(collection.localizedTitle!) (\(PhotosManager.sharedInstance.getImageFetchResultWith(collection).count))"
    
    PhotosManager.sharedInstance.getImageWith(indexPath.row, withIndex: 0, withSizeType: .Thumbnail) { (image) -> Void in
      
      if image == nil {
        return
      }
      
      cell.thumbImageView.image = image
    }
    
    cell.setSeparatorByEdge()
    
    return cell
  }
}

extension PhotoAlbumView: UITableViewDelegate {
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    tableView.deselectRow()
    
    PhotosManager.sharedInstance.currentAlbumIndex = indexPath.row
    
    delegate.photoAlbumView(self, didSelectAtIndex: indexPath.row)
  }
  
}


//
//  PhotoAlbumView.swift
//  ImagePickerProject
//
//  Created by 范祎楠 on 16/7/6.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

protocol PhotoAlbumViewDelegate: NSObjectProtocol {
  
  func photoAlbumView(_ photoAlbumView: PhotoAlbumView, didSelectAtIndex index: Int)
  
}

class PhotoAlbumView: UIView {
  
  fileprivate var tableView: UITableView!
  fileprivate weak var delegate: PhotoAlbumViewDelegate?
  
  let identifier = "PhotoAlbumCell"
  
  init(frame: CGRect, delegate: PhotoAlbumViewDelegate) {
    
    self.delegate = delegate
    
    super.init(frame: frame)
    
    setupUI()
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
  //MARK: - private Implements
  
  func setupUI(){
    
    tableView = UITableView(frame: bounds, style: .plain)
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.backgroundColor = UIColor.white
    tableView.tableFooterView = UIView()
    tableView.dataSource = self
    tableView.delegate = self
    let nibCell = UINib(nibName: identifier, bundle: Bundle(for: PhotoAlbumView.self))
    tableView.register(nibCell, forCellReuseIdentifier: identifier)
    tableView.separatorColor = UIColor.separatorColor
    tableView.rowHeight = 60.0
    addSubview(tableView)
    
    tableView.reloadData()
    
  }
  
}

extension PhotoAlbumView: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return PhotosManager.shared.getAlbumCount()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PhotoAlbumCell
    
    guard let collection = PhotosManager.shared.getAlbumWith(indexPath.row) else  { return cell }
    
    cell.titleLabel.text = "\(collection.localizedTitle!) (\(PhotosManager.shared.getFetchResult(with: collection, resourceOption: PhotosManager.shared.resourceOption).count))"
    
    PhotosManager.shared.fetchImage(with: indexPath.row, imageIndex: 0, sizeType: .thumbnail) { (image, _) -> Void in
      
      if image == nil {
        return
      }
      
      cell.thumbImageView.image = image
    }
    
    cell.separatorInset = UIEdgeInsets.zero
    
    return cell
  }
}

extension PhotoAlbumView: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if let indexPath = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: indexPath, animated: true)
    }
    PhotosManager.shared.currentAlbumIndex = indexPath.row
    
    delegate?.photoAlbumView(self, didSelectAtIndex: indexPath.row)
  }
  
}


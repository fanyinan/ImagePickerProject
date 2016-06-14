//
//  PhotoAlbumViewController.swift
//  PhotoBrowserProject
//
//  Created by 范祎楠 on 15/11/25.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {
  
  private var tableView: UITableView!
  var canOpenCamera = true
  
  let identifier = "PhotoAlbumCell"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initView()
    
    let viewController = PhotoColletionViewController()
    viewController.canOpenCamera = canOpenCamera
    navigationController?.pushViewController(viewController, animated: false)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    PhotosManager.sharedInstance.clearData()
  }
  
  func onCancel() {
    
    PhotosManager.sharedInstance.cancel()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
   //MARK: - private Implements
  
  func initView(){
    
    title = "照片"
    
    view.backgroundColor = UIColor.greenColor()
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .Plain, target: self, action: #selector(PhotoAlbumViewController.onCancel))
    setNaviBackButton("相册")
    
    tableView = UITableView(frame: view.bounds, style: .Plain)
    tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    tableView.backgroundColor = UIColor.whiteColor()
    tableView.tableFooterView = UIView()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.setNibCell(identifier)
    tableView.setSeparatorByEdge()
    tableView.separatorColor = separatorColor
    tableView.rowHeight = 60.0
    view.addSubview(tableView)
    
    tableView.reloadData()
    
  }
  
}

extension PhotoAlbumViewController: UITableViewDataSource {
  
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

extension PhotoAlbumViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    tableView.deselectRow()
    
    PhotosManager.sharedInstance.currentAlbumIndex = indexPath.row
    
    let viewController = PhotoColletionViewController()
    
    navigationController?.pushViewController(viewController, animated: true)
    
  }
  
}

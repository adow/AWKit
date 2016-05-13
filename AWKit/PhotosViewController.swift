//
//  PhotosViewController.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/12.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import UIKit
// MARK - Model
// MARK: Model for search
struct PhotosPagedModel : AWJsonModel{
    var current_page : Int!
    var total_pages : Int!
    var total_items : Int!
    var photos : [PhotoModel]! = []
    
    init(dict: [String : AnyObject]) {
        self.current_page = Int.valueFromAnyObject(dict["current_page"])
        self.total_pages = Int.valueFromAnyObject(dict["total_pages"])
        self.total_items = Int.valueFromAnyObject(dict["total_items"])
        if let photo_dict_list = dict["photos"] as? [[String:AnyObject]] {
            self.photos = PhotoModel.listFromArray(photo_dict_list)
        }
    }
    
    struct PhotoModel : AWJsonModel{
        var id : Int!
        var user_id : Int!
        var name : String!
        var description : String?
        var rating : Double!
        var created_at : String!
        var width : Double!
        var height : Double!
        var image_url : String!
        var url : String!
        init(dict: [String : AnyObject]) {
            self.id = Int.valueFromAnyObject(dict["id"])
            self.user_id = Int.valueFromAnyObject(dict["user_id"])
            self.name = String.stringFromAnyObject(dict["name"])
            self.description = String.stringFromAnyObject(dict["description"])
            self.rating = Double.valueFromAnyObject(dict["rating"])
            self.created_at = String.stringFromAnyObject(dict["created_at"])
            self.width = Double.valueFromAnyObject(dict["width"])
            self.height = Double.valueFromAnyObject(dict["height"])
            self.image_url = String.stringFromAnyObject(dict["image_url"])
            self.url = String.stringFromAnyObject(dict["url"])
        }
        
        
    }
}

class PhotosViewController: UICollectionViewController {
    var photosPaged : PhotosPagedModel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = NSURL(string: "https://api.500px.com/v1/photos?feature=editors&page=1&consumer_key=7iL5EFteZ0j3OexGdDxnPANksfPwQZtD5SPaZhne")!
        AWHttpRequest.get(url)
            .responseJSON({ [weak self](json) in
                self?.photosPaged = PhotosPagedModel(dict: json)
                self?.collectionView?.reloadData()
                }) { (error) in
                    
        }
    }
    deinit {
        NSLog("photos dealloc")
    }
}
extension PhotosViewController {
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photosPaged?.photos?.count ?? 0
    }
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell-image", forIndexPath: indexPath)
        let photo = self.photosPaged.photos[indexPath.row]
        let image_url = photo.image_url
        if let imageView = cell.contentView.viewWithTag(100) as? UIImageView {
            imageView.image = nil
            imageView.aw_downloadImageURL_loading(NSURL(string: image_url)!, showLoading: true, completionBlock: { (_, _) in
                
            })
        }
        return cell
    }
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.dismissViewControllerAnimated(true) { 
            
        }
    }
}

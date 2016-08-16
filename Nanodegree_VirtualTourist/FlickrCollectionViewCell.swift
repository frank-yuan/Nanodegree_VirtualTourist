//
//  FlickrCollectionViewCell.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/11/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit

class FlickrCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var activityIndicatorView : UIActivityIndicatorView!
    
    var flickrPhoto : FlickrPhoto? {
        didSet{
            if let fp = flickrPhoto {
                setImage(fp.image)
                if (fp.image == nil) {
                    fp.startDownload()
                }
            }
            onChanged()
        }
    }
    
    func setImage(image : NSData?) {
        
        if (image != nil) {
            imageView.image = UIImage(data: image!)
        } else {
            imageView.image = nil
        }
        onChanged()
    }
    
    func onChanged() {
        if imageView.image != nil {
            activityIndicatorView.stopAnimating()
        }
    }
}

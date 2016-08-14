//
//  ImageViewController.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/15/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    var flickrPhoto : FlickrPhoto?
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var titleLabel : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if flickrPhoto != nil{
            if  flickrPhoto?.image != nil {
                imageView.image = UIImage(data: (flickrPhoto?.image)!)
            }
            titleLabel.text = flickrPhoto?.title
        }
    }
}

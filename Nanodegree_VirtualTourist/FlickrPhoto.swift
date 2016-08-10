//
//  FlickrPhoto.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/10/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import Foundation
import CoreData

@objc(FlickrPhoto)
class FlickrPhoto: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    convenience init(id:String, url:String, mapCoordinate: MapCoordinate, context: NSManagedObjectContext)
    {
        if let ent = NSEntityDescription.entityForName("FlickrPhoto", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.id = id
            self.url = url
            self.rMapCoord = mapCoordinate
        } else {
            fatalError("Unable to find Entity Name")
        }
        
    }
    
    func startDownload() {
        performUpdatesBackground{
            let image = NSData(contentsOfURL: NSURL(string: self.url!)!)
            performUIUpdatesOnMain{
                self.image =  image
            }
        }
    }
}

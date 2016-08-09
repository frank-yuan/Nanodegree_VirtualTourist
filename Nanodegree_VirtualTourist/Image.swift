//
//  Image.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/8/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import Foundation
import CoreData

@objc(Image)
class Image: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    convenience init(id:String, url:String, context: NSManagedObjectContext)
    {
        if let ent = NSEntityDescription.entityForName("Image", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.id = id
            self.url = url
        } else {
            fatalError("Unable to find Entity Name")
        }
        
    }
}

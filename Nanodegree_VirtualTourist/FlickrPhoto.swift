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
        if let ent = NSEntityDescription.entityForName(Constants.EntityName.FlickrPhoto, inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.id = id
            self.url = url
            self.rMapCoord = mapCoordinate
        } else {
            fatalError("Unable to find Entity Name")
        }
        
    }
    
    func startDownload() {
        let entityId = self.id!
        let url = self.url!
        performUpdatesUserInteractive {
            let image = NSData(contentsOfURL: NSURL(string: url)!)
            CoreDataHelper.performCoreDataBackgroundOperation({ (workerContext) in
                
                // build fetch request to find self in background context
                let fr = NSFetchRequest(entityName: Constants.EntityName.FlickrPhoto)
                fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                let pred = NSPredicate(format: "id = %@", argumentArray: [entityId])
                fr.predicate = pred
                
                let fetchResults = try! workerContext.executeFetchRequest(fr)
                
                if let targetObject = fetchResults.first as? FlickrPhoto {
                    targetObject.image = image
                }
            })
            
        }
    }
}

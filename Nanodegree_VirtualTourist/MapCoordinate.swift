//
//  MapCoordinate.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/8/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import Foundation
import CoreData

@objc(MapCoordinate)
class MapCoordinate: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    convenience init(latitude:Double, longitude:Double, context: NSManagedObjectContext)
    {
        if let ent = NSEntityDescription.entityForName(Constants.EntityName.MapCoordinate, inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
            self.id = "\(latitude)\(longitude)"
        } else {
            fatalError("Unable to find Entity Name")
        }
    }
    
    func getSameObjectInContext(workerContext:NSManagedObjectContext) -> MapCoordinate? {
        let fr = NSFetchRequest(entityName: Constants.EntityName.MapCoordinate)
        fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let pred = NSPredicate(format: "id = %@", argumentArray: [self.id!])
        fr.predicate = pred
        let fetchResults = try! workerContext.executeFetchRequest(fr)
        if let targetObject = fetchResults.first as? MapCoordinate {
            return targetObject
        }
        return nil
    }
    
    func downloadPhotos(completionHandler:(error: String?) -> Void) {
        
        performUpdatesUserInitiated {
            if ((self.downloading) != false) {
                completionHandler(error: "Already started")
                return
            }
            
            self.downloading = true
            var page = Int(self.totalPage!)
            page = page == 0 ? 1 :  (Int(arc4random()) % page)
            FlickrService.retrieveImagesByGeo(self.toLocationCoordinate2D(), page: page) { (result, error) in
                if (error == NetworkError.NoError) {
                    
                    if let photos = result![Constants.FlickrResponseKeys.Photos],
                    photo = photos![Constants.FlickrResponseKeys.Photo] as? [AnyObject]
                    {
                        CoreDataHelper.performCoreDataBackgroundOperation(){ (workerContext) in
                            
                            // find self in background context
                            if let targetObject = self.getSameObjectInContext(workerContext){
                                
                                // overwrite page and total pages
                                targetObject.currentPage = AnyObjectHelper.parseData(photos, name: Constants.FlickrResponseKeys.Page, defaultValue: 0)
                                targetObject.totalPage = AnyObjectHelper.parseData(photos, name: Constants.FlickrResponseKeys.Pages, defaultValue: 0)
                                
                                // delete exist ones in set
                                for item in targetObject.rImage! {
                                    workerContext.deleteObject(item as! NSManagedObject)
                                }
                                // create new photos
                                for photoData in photo {
                                    
                                    let flickrPhoto = FlickrPhoto(
                                        hashObject: photoData,
                                        mapCoordinate: targetObject,
                                        context: workerContext)
                                    flickrPhoto.startDownload()
                                }
                                completionHandler(error: nil)
                            }else {
                                completionHandler(error: "Cannot find same object")
                            }
                            
                            self.downloading = false
                        }
                    }
                } else {
                    self.downloading = false
                    completionHandler(error: "Error with code:\(error.rawValue)")
                }
            }
        }
    }
}
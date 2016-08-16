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
    
    func parseFromObject(result:AnyObject?) -> Bool {
        
        if let photos = result![Constants.FlickrResponseKeys.Photos],
            photo = photos![Constants.FlickrResponseKeys.Photo] as? [AnyObject]
        {
            
            // overwrite page and total pages
            currentPage = AnyObjectHelper.parseData(photos, name: Constants.FlickrResponseKeys.Page, defaultValue: 0)
            totalPage = AnyObjectHelper.parseData(photos, name: Constants.FlickrResponseKeys.Pages, defaultValue: 0)
            
            // create new photos
            for photoData in photo {
                
                let flickrPhoto = FlickrPhoto(hashObject: photoData,
                    mapCoordinate: self,
                    context: self.managedObjectContext!)
                flickrPhoto.startDownload()
            }
            return true
        }
        return false
    }
    
    func clearImages() {
        for item in rImage! {
            self.managedObjectContext!.deleteObject(item as! NSManagedObject)
        }
    }
    
    static func getObjectInContext(workerContext:NSManagedObjectContext, byId:String) -> MapCoordinate? {
        let fr = NSFetchRequest(entityName: Constants.EntityName.MapCoordinate)
        fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let pred = NSPredicate(format: "id = %@", argumentArray: [byId])
        fr.predicate = pred
        let fetchResults = try! workerContext.executeFetchRequest(fr)
        if let targetObject = fetchResults.first as? MapCoordinate {
            return targetObject
        }
        return nil
    }
    
    static func instantiateMapCoordinate(latitude latitude:Double, longitude:Double) {
        
        CoreDataHelper.performCoreDataBackgroundOperation({ (workerContext) in
            let mapCoordinate = MapCoordinate(latitude: latitude, longitude: longitude, context: workerContext)
            mapCoordinate.downloadPhotosInPrivateQueue(){ (error) in
            }
        })
    }
    
    func downloadPhotosInPrivateQueue(completionHandler:(error: String?) -> Void) {
        self.downloading = true
        var page = min(Int(self.totalPage!), Constants.Flickr.MaxDisplayableImageCount / Constants.FlickrParameterValues.RecordPerPage)
        page = page == 0 ? 1 :  (Int(arc4random()) % page)
        FlickrService.retrieveImagesByGeo(self.toLocationCoordinate2D(), page: page) { (result, error) in
            CoreDataHelper.performCoreDataBackgroundOperation(){ (workerContext) in
                var succeed = false
                if (error == NetworkError.NoError) {
                    
                    succeed = self.parseFromObject(result)
                    
                    if (!succeed) {
                        completionHandler(error: "Error with code:\(error.rawValue)")
                    } else {
                        
                        completionHandler(error: nil)
                    }
                    self.downloading = false
                }
            }
        }
    }
}
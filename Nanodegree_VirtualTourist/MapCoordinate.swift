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
    
    func downloadPhotos(completionHandler:(error: String?) -> Void) {
        let id = self.id!
        CoreDataHelper.performCoreDataBackgroundOperation(){ (workerContext) in
            
            if let targetObject = MapCoordinate.getObjectInContext(workerContext, byId: id){
                if ((targetObject.downloading) != false) {
                    completionHandler(error: "Already started")
                    return
                }
                
                targetObject.downloading = true
                var page = min(Int(targetObject.totalPage!), Constants.Flickr.MaxDisplayableImageCount / Constants.FlickrParameterValues.RecordPerPage)
                page = page == 0 ? 1 :  (Int(arc4random()) % page)
                FlickrService.retrieveImagesByGeo(targetObject.toLocationCoordinate2D(), page: page) { (result, error) in
                    if (error == NetworkError.NoError) {
                        
                        if let photos = result![Constants.FlickrResponseKeys.Photos],
                            photo = photos![Constants.FlickrResponseKeys.Photo] as? [AnyObject]
                        {
                            
                            // find targetObject in background context
                            
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
                                    id: AnyObjectHelper.parseData(photoData, name: Constants.FlickrResponseKeys.ID, defaultValue: ""),
                                    url: AnyObjectHelper.parseData(photoData, name: Constants.FlickrResponseKeys.MediumURL, defaultValue: ""),
                                    mapCoordinate: targetObject,
                                    context: workerContext)
                                flickrPhoto.startDownload()
                            }
                            completionHandler(error: nil)
                            
                            targetObject.downloading = false
                        }
                    } else {
                        targetObject.downloading = false
                        completionHandler(error: "Error with code:\(error.rawValue)")
                    }
                }
            }
        }
    }
}
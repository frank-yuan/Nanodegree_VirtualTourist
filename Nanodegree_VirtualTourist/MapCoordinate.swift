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
        if let ent = NSEntityDescription.entityForName("MapCoordinate", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
            self.createdDate = NSDate.init(timeIntervalSinceNow: 0)
        } else {
            fatalError("Unable to find Entity Name")
        }
    }
    
    func downloadPhotos(completionHandler:(error: String?) -> Void) {
        
        performUpdatesUserInitiated {
            if ((self.downloading) != false) {
                completionHandler(error: "Already started")
                return
            }
            
            self.downloading = true
            FlickrService.retrieveImagesByGeo(self.toLocationCoordinate2D()) { (result, error) in
                if (error == NetworkError.NoError) {
                    
                    if let photos = result![Constants.FlickrResponseKeys.Photos],
                    photo = photos![Constants.FlickrResponseKeys.Photo] as? [AnyObject]
                    {
                        CoreDataHelper.performCoreDataBackgroundOperation(){ (workerContext) in
                            // delete exist ones in set
                            for item in self.rImage! {
                                workerContext.deleteObject(item as! NSManagedObject)
                            }
                            for photoData in photo {
                                
                                let flickrPhoto = FlickrPhoto(
                                    id: AnyObjectHelper.parseData(photoData, name: Constants.FlickrResponseKeys.ID, defaultValue: ""),
                                    url: AnyObjectHelper.parseData(photoData, name: Constants.FlickrResponseKeys.MediumURL, defaultValue: ""),
                                    mapCoordinate: self,
                                    context: workerContext)
                                //flickrPhoto.rMapCoord = self
                                flickrPhoto.startDownload()
                            }
                            self.downloading = false
                            completionHandler(error: nil)
                        }
                        
                    }
                } else {
                    self.downloading = false
                    completionHandler(error: "Error with code:\(error.rawValue)")
                }
            }
        }
    }
    
//    static func backgroundDownloadForMapCoordinate(mapCoordinate: MapCoordinate, context: NSManagedObjectContext, completionHandler:(result:AnyObject?, error: NetworkError) -> Void) {
//        performUpdatesUserInitiated {
//            if ((mapCoordinate.downloading) != false) {
//                return
//            }
//            mapCoordinate.downloading = true
//            FlickrService.retrieveImagesByGeo(mapCoordinate.toLocationCoordinate2D()) { (result, error) in
//                
//                if (error == NetworkError.NoError) {
//                    
//                    if let photos = result![Constants.FlickrResponseKeys.Photos],
//                    photo = photos![Constants.FlickrResponseKeys.Photo] as? [AnyObject]
//                    {
//                        
//                        for photoData in photo {
//                            
//                            if let url = photoData[Constants.FlickrResponseKeys.MediumURL] as? String{
//                                
//                                performUIUpdatesOnMain {
//                                    
//                                    let flickrPhoto = FlickrPhoto(
//                                        id: AnyObjectHelper.parseData(photoData, name: Constants.FlickrResponseKeys.ID, defaultValue: ""),
//                                        url: url,
//                                        mapCoordinate: mapCoordinate,
//                                        context: context)
//                                    flickrPhoto.rMapCoord = mapCoordinate
//                                    flickrPhoto.startDownload()
//                                }
//                            }
//                        }
//                    }
//                }
//                mapCoordinate.downloading = false
//                completionHandler(result: result, error: error)
//            }
//        }
//    }
}

//
//  FlickrPhoto+CoreDataProperties.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/15/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension FlickrPhoto {

    @NSManaged var id: String?
    @NSManaged var image: NSData?
    @NSManaged var url: String?
    @NSManaged var title: String?
    @NSManaged var rMapCoord: MapCoordinate?

}

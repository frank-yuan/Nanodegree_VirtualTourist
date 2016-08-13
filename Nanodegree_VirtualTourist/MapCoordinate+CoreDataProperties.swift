//
//  MapCoordinate+CoreDataProperties.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/13/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MapCoordinate {

    @NSManaged var downloading: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var id: String?
    @NSManaged var currentPage: NSNumber?
    @NSManaged var totalPage: NSNumber?
    @NSManaged var rImage: NSSet?

}

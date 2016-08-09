//
//  Image+CoreDataProperties.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/9/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Image {

    @NSManaged var id: String?
    @NSManaged var url: String?
    @NSManaged var image: NSData?
    @NSManaged var rMapCoord: MapCoordinate?

}

//
//  Earthquake.swift
//
//  Copyright (c) 2014 Double Encore. All rights reserved.
//

import Foundation
import CoreData

class Earthquake: NSManagedObject {

    @NSManaged var depth: NSNumber
    @NSManaged var detail: String
    @NSManaged var felt: NSNumber
    @NSManaged var quakeID: String
    @NSManaged var lastUpdated: NSDate
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var magnitude: NSNumber
    @NSManaged var place: String?
    @NSManaged var quakeTime: NSDate
    @NSManaged var url: String

}

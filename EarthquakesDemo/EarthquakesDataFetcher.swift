//
//  EarthquakesDataFetcher.swift
//
//  Copyright (c) 2014 Double Encore. All rights reserved.
//

import UIKit
import CoreData

class EarthquakesDataFetcher: NSObject {
    
    var networkSession: NSURLSession
    var storeCoordinator: NSPersistentStoreCoordinator
    var contextSavedNotification: NSNotification?
    
    init(persistentStoreCoordinator: NSPersistentStoreCoordinator!) {
        networkSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        storeCoordinator = persistentStoreCoordinator
        super.init()
    }
    
    func fetchEarthquakeData(completionHandler: ((success: Bool, error: NSError?) -> Void)?) {
        let request = NSURLRequest(URL: NSURL(string: "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson"))
        networkSession.dataTaskWithRequest(request, completionHandler:{ (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            self.parseAndSaveEarthquakes(data, response: response, error: error, completionHandler: completionHandler)
        }).resume()
        NSLog("Started fetching quakes...")
    }
    
    func parseAndSaveEarthquakes(data: NSData!, response: NSURLResponse!, error: NSError?, completionHandler: ((success: Bool, error: NSError?) -> Void)?) {
        if data != nil {
            var error: NSError? = nil
            
            let quakes: AnyObject? = (NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? Dictionary<String, AnyObject>)?["features"]
            
            let sortedQuakes = quakes?.sortedArrayUsingDescriptors([NSSortDescriptor(key: "id", ascending: true)])
            
            if let typedQuakes = sortedQuakes as? [Dictionary<String, AnyObject>] {
                let coordinator = self.storeCoordinator
                let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                context.performBlock() {
                    context.persistentStoreCoordinator = coordinator
                    NSLog("Started parsing quakes...")
                    
                    let sliceIDs = typedQuakes.map() { (quakeDict: Dictionary<String, AnyObject>) -> AnyObject? in
                        return quakeDict["id"]
                        }.filter() { (maybeID: AnyObject?) -> Bool in
                            return maybeID != nil
                        }.map() { (yesID: AnyObject?) -> AnyObject! in
                            return yesID!
                    }
                    
                    var existingObjectsRequest = NSFetchRequest(entityName: "Earthquake")
                    existingObjectsRequest.sortDescriptors = [NSSortDescriptor(key: "quakeID", ascending: true)]
                    existingObjectsRequest.predicate = NSPredicate(format: "self.quakeID IN $NEW_IDS").predicateWithSubstitutionVariables(["NEW_IDS": sliceIDs])
                    
                    let existingObjects = context.executeFetchRequest(existingObjectsRequest, error: nil) as [Earthquake]
                    
                    var existingQuakesEnumerator = existingObjects.generate()
                    var existingQuake = existingQuakesEnumerator.next()
                    
                    for quakeDictionary in typedQuakes {
                        let rawID: AnyObject? = quakeDictionary["id"]
                        let typedID = rawID as? String
                        
                        let rawProperties: AnyObject? = quakeDictionary["properties"]
                        let typedProperties = rawProperties as? Dictionary<String, AnyObject>
                        
                        let rawTime: AnyObject? = typedProperties?["time"]
                        let typedTime: NSTimeInterval? = (rawTime as? NSNumber)?.doubleValue
                        
                        let rawMag: AnyObject? = typedProperties?["mag"]
                        let typedMag: Double? = (rawMag as? NSNumber)?.doubleValue
                        
                        let rawGeometry: AnyObject? = quakeDictionary["geometry"]
                        let typedGeometry = rawGeometry as? Dictionary<String, AnyObject>
                        
                        let rawCoordinates: AnyObject? = typedGeometry?["coordinates"]
                        let typedCoordinates = rawCoordinates as? [NSNumber]
                        
                        if typedCoordinates != nil && typedCoordinates!.count == 3 && typedID != nil && typedTime != nil && typedMag != nil {
                            var quakeToUpdate: Earthquake? = nil
                            
                            if typedID == existingQuake?.quakeID {
                                quakeToUpdate = existingQuake
                                existingQuake = existingQuakesEnumerator.next()
                            }
                            else {
                                quakeToUpdate = Earthquake(entity: NSEntityDescription.entityForName("Earthquake", inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
                            }
                            
                            quakeToUpdate!.quakeID = typedID!
                            quakeToUpdate!.quakeTime = NSDate(timeIntervalSince1970: (typedTime! / 1000.0))
                            quakeToUpdate!.magnitude = typedMag!
                            quakeToUpdate!.longitude = typedCoordinates![0]
                            quakeToUpdate!.latitude = typedCoordinates![1]
                            quakeToUpdate!.depth = typedCoordinates![2]
                            
                            let rawPlace: AnyObject? = typedProperties?["place"]
                            if let typedPlace = rawPlace as? String {
                                quakeToUpdate!.place = typedPlace
                            }
                        }
                    }
                    
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: context)
                    
                    var blockError: NSError? = nil
                    if context.save(&blockError) {
                        let notif = self.contextSavedNotification
                        dispatch_async(dispatch_get_main_queue()) {
                            if notif != nil {
                                (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext.mergeChangesFromContextDidSaveNotification(notif)
                            }
                            completionHandler?(success: true, error: nil)
                        }
                        self.contextSavedNotification = nil
                    }
                    else if completionHandler != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler!(success: false, error: blockError)
                        }
                    }
                    
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: context)
                    
                    NSLog("Finished fetching quakes.")
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    NSLog("Could not fetch quakes.")
                    completionHandler?(success: false, error: error)
                }
            }
        }
    }
    
    func contextDidSave(notification: NSNotification) {
        self.contextSavedNotification = notification
    }
}

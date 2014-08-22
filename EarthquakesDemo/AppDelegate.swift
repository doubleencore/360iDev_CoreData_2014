//
//  AppDelegate.swift
//
//  Copyright (c) 2014 Double Encore. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?


    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as UINavigationController
        splitViewController.delegate = navigationController.topViewController as DetailViewController

        let masterNavigationController = splitViewController.viewControllers[0] as UINavigationController
        let controller = masterNavigationController.topViewController as MasterViewController
        controller.managedObjectContext = self.managedObjectContext
        controller.earthquakesDataFetcher = self.earthquakesDataFetcher
        return true
    }

    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

    // #pragma mark - Core Data stack

    var managedObjectContext: NSManagedObjectContext {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            self._managedObjectContext = NSManagedObjectContext()
            self._managedObjectContext!.persistentStoreCoordinator = self.persistentStoreCoordinator
        }
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil

    var managedObjectModel: NSManagedObjectModel {
        if _managedObjectModel == nil {
            let modelURL = NSBundle.mainBundle().URLForResource("EarthquakesDemo", withExtension: "momd")!
            _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
        }
        return _managedObjectModel!
    }
    var _managedObjectModel: NSManagedObjectModel? = nil

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if _persistentStoreCoordinator == nil {
            let (coordinator, error) = self.createPersistentStoreCoordinator()
            
            if coordinator == nil {
                println("Could not create persistent store coordinator: \(error), \(error?.userInfo)")
                abort()
            }
            
            _persistentStoreCoordinator = coordinator
        }
            
        return _persistentStoreCoordinator!
    }
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil

    var applicationSupportDirectory: NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        return (urls[urls.count-1] as NSURL).URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!, isDirectory: true)
    }
    
    func createApplicationSupportDirectoryIfNeeded() -> NSError? {
        var error: NSError? = nil
        NSFileManager.defaultManager().createDirectoryAtURL(self.applicationSupportDirectory, withIntermediateDirectories: true, attributes: nil, error: &error)
        return error
    }
    
    func createPersistentStoreCoordinator() -> (NSPersistentStoreCoordinator?, NSError?) {
        if let dirError = self.createApplicationSupportDirectoryIfNeeded() {
            return (nil, dirError)
        }
        
        var error: NSError? = nil
        
        let storeURL = self.applicationSupportDirectory.URLByAppendingPathComponent("EarthquakesDemo.sqlite")
        let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if newCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error) != nil {
            return (newCoordinator, nil)
        }
        else {
            return (nil, error)
        }
    }
    
    var earthquakesDataFetcher: EarthquakesDataFetcher {
        if _earthquakesDataFetcher == nil {
            _earthquakesDataFetcher = EarthquakesDataFetcher()
        }
        return _earthquakesDataFetcher!
    }
    var _earthquakesDataFetcher: EarthquakesDataFetcher? = nil
}


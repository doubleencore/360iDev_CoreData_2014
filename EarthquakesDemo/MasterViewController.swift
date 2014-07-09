//
//  MasterViewController.swift
//
//  Copyright (c) 2014 Double Encore. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    var earthquakesDataFetcher: EarthquakesDataFetcher? = nil
    var dateFormatter: NSDateFormatter? = nil
    var magnitudeFormatter: NSNumberFormatter? = nil
    
    @IBOutlet var refreshButton: UIBarButtonItem!
    var refreshSpinner: UIBarButtonItem? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        self.clearsSelectionOnViewWillAppear = false
        self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        refreshSpinner = UIBarButtonItem(customView: spinner)
        
        self.dateFormatter = NSDateFormatter()
        dateFormatter!.timeStyle = .ShortStyle;
        dateFormatter!.dateStyle = .ShortStyle;
        
        self.magnitudeFormatter = NSNumberFormatter()
        magnitudeFormatter!.positiveFormat = "2.1"
        magnitudeFormatter!.negativeFormat = "-2.1"
        magnitudeFormatter!.roundingIncrement = 0.1
        magnitudeFormatter!.roundingMode = .RoundHalfUp

        let controllers = self.splitViewController!.viewControllers
        self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
    }
    
    // #pragma mark - Actions
    
    @IBAction func refreshTapped(AnyObject) {
        self.navigationItem.rightBarButtonItem = refreshSpinner
        (refreshSpinner!.customView as UIActivityIndicatorView).startAnimating()
        self.earthquakesDataFetcher!.fetchEarthquakeData() { (success: Bool, error: NSError?) -> Void in
            if success {
                self.fetchedResultsController.performFetch(nil)
                self.tableView.reloadData()
            }
            else if let err = error {
                NSLog("Error fetching earthquakes: %@", err)
            }
            else {
                NSLog("Unknown error fetching earthquakes")
            }
            
            (self.refreshSpinner!.customView as UIActivityIndicatorView).stopAnimating()
            self.navigationItem.rightBarButtonItem = self.refreshButton
        }
    }

    // #pragma mark - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let count = self.fetchedResultsController.sections?.count {
            return count
        }
        else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }
        else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as EarthquakeTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as Earthquake
        self.detailViewController!.detailItem = object
    }

    func configureCell(cell: EarthquakeTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let earthquake = self.fetchedResultsController.objectAtIndexPath(indexPath) as Earthquake
        cell.magnitudeLabel.text = self.magnitudeFormatter!.stringFromNumber(earthquake.magnitude)
        cell.placeLabel.text = earthquake.place
        cell.dateLabel.text = self.dateFormatter!.stringFromDate(earthquake.quakeTime)
    }

    // #pragma mark - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Earthquake", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: "quakeTime", ascending: false)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController = aFetchedResultsController
        
    	var error: NSError? = nil
    	if !_fetchedResultsController!.performFetch(&error) {
             println("Unresolved error \(error), \(error!.userInfo)")
    	     abort()
    	}
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil
}


//
//  DetailViewController.swift
//
//  Copyright (c) 2014 Double Encore. All rights reserved.
//

import UIKit
import MapKit

extension Earthquake: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude.doubleValue, longitude: self.longitude.doubleValue)
    }
}

class DetailViewController: UIViewController, UISplitViewControllerDelegate, MKMapViewDelegate {

    var mapView: MKMapView!
    var masterPopoverController: UIPopoverController? = nil

    var detailItem: Earthquake? {
        didSet {
            // Update the view.
            self.configureView(detailItem)

            if self.masterPopoverController != nil {
                self.masterPopoverController!.dismissPopoverAnimated(true)
            }
        }
    }

    func configureView(maybeQuake: Earthquake?) {
        // Update the user interface for the detail item.
        if let quake = maybeQuake {
            self.mapView.addAnnotation(quake)
            self.mapView.setCenterCoordinate(quake.coordinate, animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var mapView = MKMapView()
        mapView.delegate = self
        mapView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(mapView)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["map": mapView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map]|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["map": mapView]))
        self.mapView = mapView
        
        self.configureView(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // #pragma mark - Split view

    func splitViewController(splitController: UISplitViewController, willHideViewController viewController: UIViewController, withBarButtonItem barButtonItem: UIBarButtonItem, forPopoverController popoverController: UIPopoverController) {
        barButtonItem.title = "Master" // NSLocalizedString(@"Master", @"Master")
        self.navigationItem.setLeftBarButtonItem(barButtonItem, animated: true)
        self.masterPopoverController = popoverController
    }

    func splitViewController(splitController: UISplitViewController, willShowViewController viewController: UIViewController, invalidatingBarButtonItem barButtonItem: UIBarButtonItem) {
        // Called when the view is shown again in the split view, invalidating the button and popover controller.
        self.navigationItem.setLeftBarButtonItem(nil, animated: true)
        self.masterPopoverController = nil
    }

}


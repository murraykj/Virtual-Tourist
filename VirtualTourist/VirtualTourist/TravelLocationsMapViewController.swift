//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/14/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

//
//  This View Controller displays a map. If the user changes
//  the map region (the center and the zoom level), then the
//  app persists the change. How does it work?
//
//  (In order to include the MapKit classes, the app needs to be
//  congifured. Click on the "MemoryMap" icon in the navigator,
//  then the "Capabilities" tab. Notice that "Maps" is turned on)
//

import UIKit
import MapKit
import CoreData


class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

//  var pins = [Pin]()
//  var temporaryContext: NSManagedObjectContext!
  var pinToBeUpdated: Pin!
  
  @IBOutlet weak var mapView: MKMapView!

  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    // Create and set the right EDIT button; this will be used to delete Pins
//    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "removePin")
    
    // restore map to previously save location
    restoreMapRegion(false)
    
    // invoke fetchedResultsController to retreive all pins.....
    do {
      try fetchedResultsController.performFetch()
    } catch {
      print("Fetch Error (Pins):  \(error)")
    }
    
    // ...and then annotate the map
    for pin in fetchedResultsController.fetchedObjects!{
      self.annotateMap(pin as! Pin)
    }

  }

  

  // #MARK: - Core Data Components
  
  // A convenience property to set the filepath to store the map region
  var filePath : String {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
    return url.URLByAppendingPathComponent("mapRegionArchive").path!
  }
  

  // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance().managedObjectContext
  }
  
  
  // Add the lazy Fetched Results Controller property
  lazy var fetchedResultsController: NSFetchedResultsController = {
    
    let fetchRequest = NSFetchRequest(entityName: "Pin")
    
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
      managedObjectContext: self.sharedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    
    return fetchedResultsController
    
  }()

  
  // #MARK: - Map Functions

  func restoreMapRegion(animated: Bool) {
    
    // if we can unarchive a dictionary, we will use it to set the map back to its previous center and span
    if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
      
      let longitude = regionDictionary["longitude"] as! CLLocationDegrees
      let latitude = regionDictionary["latitude"] as! CLLocationDegrees
      let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      
      let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
      let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
      let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
      
      let savedRegion = MKCoordinateRegion(center: center, span: span)
      
      print("Map Restored:  lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
      
      mapView.setRegion(savedRegion, animated: animated)
    }
  }
  
  
  // function to annotate the map; called during load process
  func annotateMap(pin:Pin){
    
    // create annotation object and set coordinates
    let annotation = MKPointAnnotation()
    
    // set lat & long
    annotation.coordinate.latitude = pin.latitude
    annotation.coordinate.longitude = pin.longitude
    
    // annotate map by placing pin on map
    self.mapView.addAnnotation(annotation)
    
  }
  
  
  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    saveMapRegion()
  }
  
  
  // save the current map region
  func saveMapRegion() {
    
    // Place the "center" and "span" of the map into a dictionary
    // The "span" is the width and height of the map in degrees.
    // It represents the zoom level of the map.
    
    let dictionary = [
      "latitude" : mapView.region.center.latitude,
      "longitude" : mapView.region.center.longitude,
      "latitudeDelta" : mapView.region.span.latitudeDelta,
      "longitudeDelta" : mapView.region.span.longitudeDelta
    ]
    
    // Archive the dictionary into the filePath
    NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    
    print("Map Saved:  \(dictionary)")
  }
  
  
  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
    let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
    annotationView.canShowCallout = false
    
    return annotationView
  }
  
  
  // #MARK: - Pin Functions
  
  // determine which Pin was selected and capture Lat/Long before segue way
  func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
    mapView.deselectAnnotation(view.annotation, animated: true)
    
    // obtain lat and long of selected Pin
    let sLatitude = view.annotation!.coordinate.latitude
    let sLongitude = view.annotation!.coordinate.longitude
    
//    print("sLat: \(sLatitude)")
//    print("sLong: \(sLongitude)")
    
    // invoke fetchedResultsController to retreive all pins.....
    do {
      try fetchedResultsController.performFetch()
    } catch {
      print("Fetch Error (Pins):  \(error)")
    }

    // usiing results of Fetched Results controller, compare pins to determine which one was selected
    for pin in fetchedResultsController.fetchedObjects!{
      
      if (pin.latitude == sLatitude) && (pin.longitude == sLongitude) {
        // if selected Pin matches, assign to selectedPIN to be passed to next controller
        let selectedPin = pin
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        
        // prepare data to be passed to next VC
        controller.selectedPin = selectedPin as! Pin
        
        // navigate to PhotoAlbumViewController
        self.navigationController!.pushViewController(controller, animated: true)
        
      }

    }
    
  }

  
  // Add pin to map
  @IBAction func addPin(sender: UILongPressGestureRecognizer) {
    
    if sender.state == UIGestureRecognizerState.Began {
    
      // Get location and convert to coordinates
      let location = sender.locationInView(self.mapView)
      let locationCoordinates = self.mapView.convertPoint(location, toCoordinateFromView: self.mapView)
      
//      print("location:  \(location), locationCoordinates: \(locationCoordinates)")
      
      // create annotation object and set coordinates
      let annotation = MKPointAnnotation()
      annotation.coordinate = locationCoordinates
      
      // Debugging output
//      print("Coord to add - Lat: \(locationCoordinates.latitude),  Long: \(locationCoordinates.longitude)")

      let coordinateDictionary: [String : AnyObject] = [
        Pin.Keys.Latitude: annotation.coordinate.latitude,
        Pin.Keys.Longitude: annotation.coordinate.longitude
      ]
      
      // Now we create a new Pin, using the shared Context and save the data
      let pinToBeAdded = Pin(dictionary: coordinateDictionary, context: self.sharedContext)
      
      CoreDataStackManager.sharedInstance().saveContext()
      
//      print("ADDED PIN: \(pinToBeAdded)")
      
      // annotate map by placing pin on map
      self.annotateMap(pinToBeAdded)
      
      
      
//# TODO: add code to pre-fetch images
      
//      // Pre-fetch picture images.
//      // invoke fetchedResultsController to retreive all pins.....
//      do {
//        try fetchedResultsController.performFetch()
//      } catch {
//        print("Fetch Error (Pins):  \(error)")
//      }
//      
//      // usiing results of Fetched Results controller, compare pins to determine which one was added
//      for pin in fetchedResultsController.fetchedObjects!{
//        
//        if (pin.latitude == annotation.coordinate.latitude) && (pin.longitude == annotation.coordinate.longitude) {
//          // if selected Pin matches, assign to selectedPIN to be passed to next controller
//          let pinToBeUpdated = pin
//          print(pinToBeUpdated)
//          
//          VTClient.sharedInstance.prefetchPictures(pinToBeUpdated as! Pin)
//          
//          CoreDataStackManager.sharedInstance().saveContext()
//          
//        }
//      }
      
//      
//      dispatch_async(dispatch_get_main_queue()) {
//        VTClient.sharedInstance.prefetchPictures(self.pinToBeUpdated)
//      }
      
      

    }
    

  }

  //# TODO: add code to allow Pin to be removed
  // Function to remove pins
  func removePin() {
    
    // add code to allow Pin to be removed
    return
  }

}




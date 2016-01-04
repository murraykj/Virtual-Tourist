//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/16/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
  
  
  var cellCreationCounter: Int = 0
  
  var selectedPin: Pin!
  var imagePageCounter: Int = 0
  
  var screenSize: CGRect!
  var screenWidth: CGFloat!
  var screenHeight: CGFloat!
  
  // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
  // used inside cellForItemAtIndexPath to lower the alpha of selected cells.
  var selectedIndexes = [NSIndexPath]()
  
  // Keep the changes. We will keep track of insertions, deletions, and updates.
  var insertedIndexPaths: [NSIndexPath]!
  var deletedIndexPaths: [NSIndexPath]!
  var updatedIndexPaths: [NSIndexPath]!
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var bottomButton: UIButton!
  
  
  // MARK: - Core Data Convenience
  
  // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
  lazy var sharedContext: NSManagedObjectContext =  {
    return CoreDataStackManager.sharedInstance().managedObjectContext
  }()
  
  
  func saveContext() {
    CoreDataStackManager.sharedInstance().saveContext()
  }
  
  
  // declaration of lazy var fetchedResultsController
  lazy var fetchedResultsController: NSFetchedResultsController = {
    
    let fetchRequest = NSFetchRequest(entityName: "Picture")
    
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedPin);          // <-- Select based on Selected Pin
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
      managedObjectContext: self.sharedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    
    return fetchedResultsController
    
  }()
  
  // MARK: - Standard ViewController Functions
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    // clear Flickr image Page counter
    imagePageCounter = 0
    
    // Display map and center on pin
    displayMap()
    
    // invoke fetchedResultsController to retreive all pictures for selected Pin.....
    do {
      try fetchedResultsController.performFetch()
    } catch {
      print("Fetch Error (Pictures):  \(error)")
    }
    
    // Set the delegate to this view controller
    fetchedResultsController.delegate = self
    collectionView.delegate = self
    collectionView.dataSource = self

  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    collectionView.allowsMultipleSelection = true
    collectionView.userInteractionEnabled = true
    
    
    // check to see if pictures have already been downloaded and saved
    if selectedPin.pictures.isEmpty {

      bottomButton.enabled = false
      
      print("No pictures!  Need to retreive them.")
      
      // if no pictures, start the download.....
      self.downloadPictureDetails(selectedPin)
      
    } else {
      print("Pictures already downloaded")
    }
    
  }
  
  // MARK: - UICollectionView Layout
  
  // Layout the collection view
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // obtain screen information for current device
    screenSize = UIScreen.mainScreen().bounds
    screenWidth = screenSize.width
    screenHeight = screenSize.height
    
    // Lay out the collection view so that cells take up 1/3 of the width,
    // with no space in between.
    let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    layout.itemSize = CGSize(width: screenWidth / 3, height: screenWidth / 3)
    
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    
    let width = floor(self.collectionView.frame.size.width/3)
    layout.itemSize = CGSize(width: width, height: width)
    collectionView.collectionViewLayout = layout
  }

  
  
  // MARK: - Map Functions
  
  // This function obtains the point that was selected and tehn centers and annotates the map
  func displayMap(){
    
    // Get lat and long of Pin selected
    let sLatitude = selectedPin.latitude
    let sLongitude = selectedPin.longitude
    
    print("lat: \(sLatitude), long: \(sLongitude)")
    
    // set size and region of map to be displayed
    let location = CLLocationCoordinate2DMake(sLatitude, sLongitude)
    let reg = MKCoordinateRegionMakeWithDistance(location, 250000, 250000)
    self.mapView.region = reg
    
    // create annotation object and set coordinates
    let annotation = MKPointAnnotation()
    
    // set lat & long for annotation/pin placement
    annotation.coordinate.latitude = sLatitude
    annotation.coordinate.longitude = sLongitude
    
    // annotate map by placing pin on map
    self.mapView.addAnnotation(annotation)
  }

  
  //# MARK: Configure Cell
  
  func configureCell(cell: PhotoCell, indexPath: NSIndexPath) {
    
    let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
    
    cellCreationCounter = cellCreationCounter + 1
    print("cellCreationCounter:  \(cellCreationCounter)")
    
    cell.imagePlaceholder.hidden = false
    cell.imageActivityIndicator.hidden = false
    cell.imageActivityIndicator.startAnimating()
    
    var image = UIImage()
    
    // no image has been downloaded....show placeholder
    if picture.imagePath == nil || picture.imagePath == "" {
      
      cell.imagePlaceholder.hidden = true
      cell.imageActivityIndicator.stopAnimating()
      cell.imageActivityIndicator.hidden = true
      
      self.bottomButton.enabled = false
      
      image = UIImage(named: "noImage")!
      
    } else if picture.image != nil {
      cell.imagePlaceholder.hidden = true
      cell.imageActivityIndicator.stopAnimating()
      cell.imageActivityIndicator.hidden = true
      
      self.bottomButton.enabled = true
      
      image = picture.image!

    }
    
    else { // The picture is not downloaded yet.
      
      print("paths exists but no images")
      let task = VTClient.sharedInstance.taskForImage(picture.imagePath!) { data, error in
        
        if let error = error {
          print("Poster download error: \(error.localizedDescription)")
        }
        
        if let data = data {
          
          let image = UIImage(data:data)
          
          // The below line is moved inside of dispatch_async for thread-safe operation
          // pic.pinnedImage = image
          
          dispatch_async(dispatch_get_main_queue()) {
            
            // update the model, so that the information gets cashed
            picture.image = image
            
            cell.image!.image = image
            self.bottomButton.enabled = true
            cell.imagePlaceholder.hidden = true
            cell.imageActivityIndicator.stopAnimating()
            cell.imageActivityIndicator.hidden = true
          }
        }
      }
      cell.taskToCancelifCellIsReused = task
    }
    
    cell.image!.image = image
    
    // grey out or un grey out images that were selected or deselected
    if let index = selectedIndexes.indexOf(indexPath) {
      cell.image.alpha = 0.05
    } else {
      cell.image.alpha = 1.0
    }
    
  }
  
  
  
  // MARK: - UICollectionView
  
  // Determine how many sections to display
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return self.fetchedResultsController.sections?.count ?? 0
  }
  
  // Determine how many items each section should contain
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionInfo = self.fetchedResultsController.sections![section]

    return sectionInfo.numberOfObjects
  }
  
  // method to return a single cell
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

    let CellIdentifier = "CollectionViewCell"
   
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! PhotoCell
    
    cell.backgroundColor = UIColor.whiteColor()
    cell.layer.borderColor = UIColor.blackColor().CGColor
    cell.layer.borderWidth = 0.1
    cell.frame.size.width = screenWidth / 3
    cell.frame.size.height = screenWidth / 3
    
    // This is the new configureCell method
    configureCell(cell, indexPath: indexPath)

    return cell
    
    }

  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
    
    // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
    if let index = selectedIndexes.indexOf(indexPath) {
      selectedIndexes.removeAtIndex(index)
    } else {
      selectedIndexes.append(indexPath)
    }
    
    // Then reconfigure the cell
    configureCell(cell, indexPath: indexPath)
    
    // And update the buttom button
    updateBottomButton()

  }
  
  
  func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
   
    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
    
    // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
    if let index = selectedIndexes.indexOf(indexPath) {
      selectedIndexes.removeAtIndex(index)
    } else {
      selectedIndexes.append(indexPath)
    }
  
    // Then reconfigure the cell
    configureCell(cell, indexPath: indexPath)
    
    // And update the buttom button
    updateBottomButton()

  }

  
  // MARK: - Fetched Results Controller Delegate functions
  
  // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
  // three fresh arrays to record the index paths that will be changed.
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    // We are about to handle some new changes. Start out with empty arrays for each change type
    insertedIndexPaths = [NSIndexPath]()
    deletedIndexPaths = [NSIndexPath]()
    updatedIndexPaths = [NSIndexPath]()
    
    print("in controllerWillChangeContent")
  }
  
  // The second method may be called multiple times, once for each Picture object that is added, deleted, or changed.  The index paths are stored into one of the three arrays.
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
    forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
      
    switch type{
        
      case .Insert:
        print("Insert an item")
        // Here we are noting that a new picture has been added to Core Data. We remember its index path
        // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
        // the index path that we want in this case
        insertedIndexPaths.append(newIndexPath!)
        break
      case .Delete:
        print("Delete an item")
        // Here we are noting that a picture has been deleted from Core Data. We keep remember its index path
        // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
        // value that we want in this case.
        deletedIndexPaths.append(indexPath!)
        break
      case .Update:
        print("Update an item.")
        // We don't expect pictures to change after they are created. But Core Data would
        // notify us of changes if any occured. This can be useful if you want to respond to changes
        // that come about after data is downloaded. For example, when an images is downloaded from
        // Flickr in the Virtual Tourist app
        updatedIndexPaths.append(indexPath!)
        break
      case .Move:
        print("Move an item. We don't expect to see this in this app.")
        break
      default:
        break
      }
  }
  
  // This method is invoked after all of the changed in the current batch have been collected
  // into the three index path arrays (insert, delete, and upate). We now need to loop through the
  // arrays and perform the changes.
  //
  // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
  // Notice that all of the changes are performed inside a closure that is handed to the collection view.
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    
    print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
    
    collectionView.performBatchUpdates({() -> Void in
      
      for indexPath in self.insertedIndexPaths {
        self.collectionView.insertItemsAtIndexPaths([indexPath])
      }
      
      for indexPath in self.deletedIndexPaths {
        self.collectionView.deleteItemsAtIndexPaths([indexPath])
      }
      
      for indexPath in self.updatedIndexPaths {
        self.collectionView.reloadItemsAtIndexPaths([indexPath])
      }
      
      }, completion: nil)
  }
  

  //# MARK: - Download Images
  
  // Function to refresh current viewcontroller; called by viewWillAppear
  func downloadPictureDetails(selectedPin: Pin) {
    
    // set page counter so the same images aren't downloaded each time.
    imagePageCounter = imagePageCounter + 1
    
    VTClient.sharedInstance.getFlickrPhotosByLatLon(selectedPin, pageNumber: imagePageCounter) {success, parsedResult, errorCode, errorText in
      
      // if successful.......
      if (success == true) && (errorCode == nil) {

        // continue next step
        if let photosDictionaries = parsedResult!.valueForKey("photo") as? [[String : AnyObject]]{
          
          if (photosDictionaries.count > 0) {
            
            print("pic count : \(photosDictionaries.count)")
            dispatch_async(dispatch_get_main_queue()) {
              
              // Parse the array of movies dictionaries
              photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Picture in
                print(dictionary)
                let picture = Picture(dictionary: dictionary, context: self.sharedContext)
                
                print("Saving picture details in downloadPictureDetails")
                
                // link picture to Pin
                picture.location = self.selectedPin
                
                self.saveContext()
                return picture
              }
            }
          }
          
        } else {
          let error = NSError(domain: "Picture for Pin Parsing. Cant find photo in \(parsedResult)", code: 0, userInfo: nil)
          print(error)
        }
        
      }else {
        // Print error and display alert to the user
        print("Error:  \(errorCode!) - \(errorText!)")
        
        dispatch_async(dispatch_get_main_queue()) {
          
          // Set alert title and text
          let alertTitle = errorCode
          let alertMessage = errorText
          
          // Display alert message
          self.displayAlertMessage(alertTitle!, message: alertMessage!)
        }
      }
    }
    // Save the context
    self.saveContext()
  }
  
  
  //# MARK: - Alert Messages
  // Generic function to display alert messages to users
  func displayAlertMessage(title: String, message: String) {
    dispatch_async(dispatch_get_main_queue(), {    let controller = UIAlertController()
      
      // set alert title and message using data passed to function
      controller.title = title
      controller.message = message
      
      let okAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil)
      
      // add buttons and display message
      controller.addAction(okAction)
      self.presentViewController(controller, animated: true, completion: nil)
    })
  }
  
  // Bottom button was clicked
  @IBAction func bottomButtonClicked() {
    
    if selectedIndexes.isEmpty {
      // user wants a new collection so, delete all pictures
      deleteAllPictures()
      
      // update core data with items that were deleted
      CoreDataStackManager.sharedInstance().saveContext()
      
      // start the download of the new collection....
      self.downloadPictureDetails(selectedPin)
    
    } else {
      // delete only selected pictures
      deleteSelectedPictures()
      
      // update core data with items that were deleted
      CoreDataStackManager.sharedInstance().saveContext()
    }
    
    collectionView.reloadData()
  }
  
  // function to delete all images; called prior to downloading new collection
  func deleteAllPictures() {
    
    // delete all pictures in core data one by one
    for picture in fetchedResultsController.fetchedObjects as! [Picture] {
      sharedContext.deleteObject(picture)
      VTClient.Caches.imageCache.removeImage(picture.imagePath!)
    }
    
    // update button text
    updateBottomButton()
    
  }
  
  // function to delete selected images only
  func deleteSelectedPictures() {
    var picturesToDelete = [Picture]()
    
    for indexPath in selectedIndexes {
      picturesToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Picture)
    }
    
    // delete pictures one by one...
    for picture in picturesToDelete {
      sharedContext.deleteObject(picture)
      VTClient.Caches.imageCache.removeImage(picture.imagePath!)
    }
    
    selectedIndexes = [NSIndexPath]()
    
    // update button text
    updateBottomButton()
  }
  
  func updateBottomButton() {
    // change button text based on what is selected in collection view
    if selectedIndexes.count > 0 {
      self.bottomButton.setTitle("Remove Selected Pictures", forState: UIControlState.Normal)
    } else {
      self.bottomButton.setTitle("New Collection", forState: UIControlState.Normal)
    }
  }
  
}


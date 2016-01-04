//
//  Picture.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/16/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// Make Picture available to Objective-C code
@objc(Picture)

// Make Picture a subclass of NSManagedObject
class Picture : NSManagedObject {
  
//  struct Keys {
//    static let Title = "title"
//    static let ImageURL = "url_m"
//    static let ImagePath = "photoURL"
//    
//  }
  
  // We are promoting these four from simple properties to Core Data attributes
  @NSManaged var title: String
  @NSManaged var imageURL: String?
  @NSManaged var imagePath: String?
  @NSManaged var location: Pin?
  
  // Include this standard Core Data init method.
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  // Implement the two argument Init method. The method has two goals:
  //  - insert the new Picture into a Core Data Managed Object Context
  //  - initialze the Picture's properties from a dictionary
  
  init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
    // Get the entity associated with the "Picture" type.  This is an object that contains the information from the Model.xcdatamodeld file.
    let entity =  NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
    
    // Call the init method that we have inherited from NSManagedObject.  The Picture class is a subclass of NSManagedObject.
    // This inherited init method does the work of "inserting" our object into the context that was passed in as a parameter.
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    // After the Core Data work has been taken care of we can init the properties from the dictionary
    title = dictionary["title"] as! String
    imagePath = dictionary["url_m"] as? String
    imageURL = dictionary["imageURL"] as? String
    
    print("imagePath: \(imagePath)")
    print("imageURL: \(imageURL)")
  }
  

  //# TODO: does this need to be removed?  was used to prefetch images; may no longer be needed for pre-fetch
  
//  //  Download pictures one by one
//  func downloadPictureImage(picture: Picture) {
//
//    // set image URL to be used
//    self.imageURL = picture.imageURL!
//    
//    // Create unique ID and save imagePath for each picture
//    let uuid = NSUUID().UUIDString   // create unique ID for each picture
//    picture.imagePath = "img_\(uuid)"
//    
//    if self.imageURL != "" {
//      // get URL for current image
//      if let imageURLString = NSURL(string: self.imageURL!) {
//        // create data object from data at URL
//        if let imageData = NSData(contentsOfURL: imageURLString) {
//
//          // create image object from previously created NSData object
//          let image = UIImage(data: imageData)
//          // assign new created image object to local object and begin to save image
//          self.image = image!
//          
//          print("Saving picture photo to device in downloadPictureImage")
//          
//          VTClient.Caches.imageCache.storeImage(image, withIdentifier: self.imagePath!)
//          print("photo downloaded:  \(self.imagePath)")
//          dispatch_async(dispatch_get_main_queue(), {
//            CoreDataStackManager.sharedInstance().saveContext()
//          })
//        }
//      } else {
//        print("could not retreive URL for photo")
//      }
//    }
//  }
  
  
  
  var image: UIImage? {
    
    get {
      let url = NSURL(fileURLWithPath: imagePath!)
      let fileName = url.lastPathComponent
      return VTClient.Caches.imageCache.imageWithIdentifier(fileName!)
    }
    
    set {
      let url = NSURL(fileURLWithPath: imagePath!)
      let fileName = url.lastPathComponent
      VTClient.Caches.imageCache.storeImage(newValue, withIdentifier: fileName!)
    }
  }
}
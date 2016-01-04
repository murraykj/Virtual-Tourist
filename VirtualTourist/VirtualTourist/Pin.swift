//
//  Pin.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/16/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import Foundation
import CoreData

// Make Pin available to Objective-C code
@objc(Pin)

// Make Pin a subclass of NSManagedObject
class Pin : NSManagedObject {
  
  struct Keys {
    static let Latitude = "latitude"
    static let Longitude = "longitude"
    static let Pictures = "pictures"
  }
  
  
  // We are promoting these three from simple properties to Core Data attributes
  @NSManaged var latitude: Double
  @NSManaged var longitude: Double
  @NSManaged var pictures: [Picture]
  
  
  // Include this standard Core Data init method.
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  
  // Implement the two argument Init method. The method has two goals:
  //  - insert the new Person into a Core Data Managed Object Context
  //  - initialze the Person's properties from a dictionary
  
  init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
    // Get the entity associated with the "Pin" type.  This is an object that contains the information from the Model.xcdatamodeld file.
    let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
    
    // Call the init method that we have inherited from NSManagedObject.  The Pin class is a subclass of NSManagedObject. 
    // This inherited init method does the work of "inserting" our object into the context that was passed in as a parameter.
    super.init(entity: entity,insertIntoManagedObjectContext: context)
    
    // After the Core Data work has been taken care of we can init the properties from the dictionary
    latitude = dictionary[Keys.Latitude] as! Double
    longitude = dictionary[Keys.Longitude] as! Double
  }
  
}

//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 11/13/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import UIKit

class ImageCache {
  
  private var inMemoryCache = NSCache()
  
  // Retreiving images
  func imageWithIdentifier(identifier: String?) -> UIImage? {
    
    // If the identifier is nil, or empty, return nil
    if identifier == nil || identifier! == "" {
      return nil
    }
    
    let path = pathForIdentifier(identifier!)
    
    // First try the memory cache
    if let image = inMemoryCache.objectForKey(path) as? UIImage {
      return image
    }
    
    // Next Try the hard drive
    if let data = NSData(contentsOfFile: path) {
      return UIImage(data: data)
    }
    
    return nil
  }
  
  // Saving images
  func storeImage(image: UIImage?, withIdentifier identifier: String) {
    let path = pathForIdentifier(identifier)
    
    // If the image is nil, remove images from the cache
    if image == nil {
      inMemoryCache.removeObjectForKey(path)
      
      do {
        try NSFileManager.defaultManager().removeItemAtPath(path)
        print("Removing image - step 2:  \(identifier)")
      } catch _ {}
      
      return
    }
    
    // Otherwise, keep the image in memory
    inMemoryCache.setObject(image!, forKey: path)
    
    // And in documents directory
    let data = UIImagePNGRepresentation(image!)!
    data.writeToFile(path, atomically: true)
    print("Adding image:  \(identifier)")
  }
  
  // Remove images
  func removeImage(identifier: String){
    print("Removing image - step 1:  \(identifier)")
    
    let url = NSURL(fileURLWithPath: identifier)
    let fileName = url.lastPathComponent
    
    storeImage(nil, withIdentifier: fileName!)
  }
  
  // Helper
  func pathForIdentifier(identifier: String) -> String {
    let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
    
    return fullURL.path!
  }
}
//
//  VTFlickr.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/16/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//


import UIKit
import Foundation
import CoreData

extension VTClient {
  
  //  Flickr API Methods
  
  // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance().managedObjectContext
    
  }

  
//# TODO: finish code to pre-fetch images  
  
//  // Function to prefetch images after Pin is added
//  func prefetchPictures(newPin: Pin) {
//    
//    // set page counter to 1 for first download.
//    let imagePageCounter: Int = 1
//    
//    getFlickrPhotosByLatLon(newPin, pageNumber: imagePageCounter) {success, parsedResult, errorCode, errorText in
//      
//      print(newPin)
//      
//      // if successful.......
//      if (success == true) && (errorCode == nil) {
//        // continue next step
//        
//        if let photosDictionaries = parsedResult!.valueForKey("photo") as? [[String : AnyObject]] {
//          
//          // Parse the array of movies dictionaries
//          photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Picture in
//            let picture = Picture(dictionary: dictionary, context: self.sharedContext)
//            
//            print("Saving picture details in downloadPictureDetails")
//            
//            // link picture to Pin
//            picture.location = self.newPin
//            
//            // Save URL and imagePath for each picture
//            picture.imageURL = dictionary["url_m"] as? String
//            
//            print(picture)
//            
//            // save picture image to device
//            if picture.imageURL != "" {
//              
//              // download photos here
//              picture.downloadPictureImage(picture)
//              
//            } else {
//              print("no photo URL")
//            }
//            
//            return picture
//          }
//          
////          // Save the context - moved to calling function
////          CoreDataStackManager.sharedInstance().saveContext()
//          
//        } else {
//          let error = NSError(domain: "Picture for Pin Parsing. Cant find photo in \(parsedResult)", code: 0, userInfo: nil)
//          print(error)
//        }
//        
//      }else {
//        // Print error and display alert to the user
//        print("Error:  \(errorCode!) - \(errorText!)")
//        
//      }
//    }
//  }
  
  
  
  
  
  
  
  
  
  func getFlickrPhotosByLatLon(selectedPin: Pin, pageNumber: Int, completionHandler: (success: Bool, parsedResult: AnyObject?, errorCode: String?, errorText: String?) -> Void) {
    
    // Convert Selected Pin latitude & longitude to strings
    let latitudeDouble = selectedPin.latitude
    let latitude = "\(latitudeDouble)"
    
    let longitudeDouble = selectedPin.longitude
    let longitude = "\(longitudeDouble)"
    
    print("pageNumber: \(pageNumber)")
    let sPageNumber = String(pageNumber)
    
    /* 1 - hard code the arguments */
    let methodArguments = [
      "method": VTClient.Constants.METHOD_NAME,
      "api_key": VTClient.Constants.API_KEY,
      "bbox": createBoundingBoxString(latitude, longitude: longitude),
      "safe_search": VTClient.Constants.SAFE_SEARCH,
      "extras": VTClient.Constants.EXTRAS,
      "format": VTClient.Constants.DATA_FORMAT,
      "nojsoncallback": VTClient.Constants.NO_JSON_CALLBACK,
      "lat": latitude,
      "lon": longitude,
      "page": sPageNumber,                      // page number is passed in by calling function; always starts with page 1 for each collection and then increments
      "per_page": VTClient.Constants.PER_PAGE
    ]
    
    let session = NSURLSession.sharedSession()
    let urlString = VTClient.Constants.BASE_URL + escapedParameters(methodArguments)
    let url = NSURL(string: urlString)!
    let request = NSURLRequest(URL: url)
    
    let task = session.dataTaskWithRequest(request) {data, response, error in
      if error != nil {
        
        // set status code for Alert message to user - network error
        completionHandler(success: false, parsedResult: nil, errorCode: "Network Error", errorText: "The Internet connection appears to be offline.")
        
      } else {
        
        let parsedInitialResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary

//        print("initial parsed result: \(parsedInitialResult)")
        
        if let photosDictionary = parsedInitialResult.valueForKey("photos") as? [String:AnyObject] {
          
          var totalPhotosVal = 0
          if let totalPhotos = photosDictionary["total"] as? String {
            totalPhotosVal = (totalPhotos as NSString).integerValue
            print("# of photos available: \(totalPhotosVal)")
            
            completionHandler(success: true, parsedResult: photosDictionary, errorCode: nil, errorText: nil)
            
          } else {
            completionHandler(success: false, parsedResult: nil, errorCode: "No Photos Found", errorText: "No photos were downloaded (2).")
  
            print("Cant find key 'total' in \(photosDictionary)")
          }
        } else {
          // set status code for Alert message to user - invalid credentials
          completionHandler(success: false, parsedResult: nil, errorCode: "No Photos Found", errorText: "photos key missing from parsed data (1).")
          
          print("Cant find key 'photos' in \(parsedInitialResult)")
        }
      }
    }
    
    task.resume()
    
  }
  
  
  func createBoundingBoxString(latitude: String, longitude: String) -> String {
    
    let latitude = NSString(string: latitude)
    let latitudeDbl = latitude.doubleValue
    
    let longitude = NSString(string: longitude)
    let longitudeDbl = longitude.doubleValue
    
    /* Fix added to ensure box is bounded by minimum and maximums */
    let bottom_left_lon = max(longitudeDbl - VTClient.Constants.BOUNDING_BOX_HALF_WIDTH, VTClient.Constants.LON_MIN)
    let bottom_left_lat = max(latitudeDbl - VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT, VTClient.Constants.LAT_MIN)
    let top_right_lon = min(longitudeDbl + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT, VTClient.Constants.LON_MAX)
    let top_right_lat = min(latitudeDbl + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT, VTClient.Constants.LAT_MAX)
    
    return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    
  }
  
  
  /* Helper function: Given a dictionary of parameters, convert to a string for a url */
  func escapedParameters(parameters: [String : AnyObject]) -> String {
    
    var urlVars = [String]()
    
    for (key, value) in parameters {
      
      /* Make sure that it is a string value */
      let stringValue = "\(value)"
      
      /* Escape it */
      let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
      
      /* Append it */
      urlVars += [key + "=" + "\(escapedValue!)"]
      
    }
    
    return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
  }
  
  
  // MARK: - All purpose task method for images
  func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
    
    let url = NSURL(string: filePath)!
    print(url)
    
    let request = NSURLRequest(URL: url)
    
    let task = session.dataTaskWithRequest(request) {data, response, downloadError in
      
      if let error = downloadError {
        completionHandler(imageData: nil, error: error)
      } else {
        completionHandler(imageData: data, error: nil)
      }
    }
    
    task.resume()
    
    return task    }
  
  
  
  
}
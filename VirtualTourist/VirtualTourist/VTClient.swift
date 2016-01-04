//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/22/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import Foundation
import UIKit

class VTClient : NSObject {
  
  /* Shared session */
  var session: NSURLSession
  
  /* User data */
  var selectedLatitude: String? = nil
  var selectedLongitude: String? = nil
  var newPin: Pin!
  

  override init() {
    session = NSURLSession.sharedSession()
    super.init()
  }
  
  
  // Shared Instance
  static let sharedInstance = VTClient()
  
  
  // Shared Image Cache
  struct Caches {
    static let imageCache = ImageCache()
  }
  
}
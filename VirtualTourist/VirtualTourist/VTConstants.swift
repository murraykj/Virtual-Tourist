//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 10/22/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import Foundation

extension VTClient {
  
  // Constants
  struct Constants {
    
    // set constants for use with Flickr
    static let  BASE_URL = "https://api.flickr.com/services/rest/"
    static let  METHOD_NAME = "flickr.photos.search"
    static let  API_KEY = "007da73dc85fc090668dbb1dca611888"
    static let  EXTRAS = "url_m"
    static let  SAFE_SEARCH = "1"
    static let  DATA_FORMAT = "json"
    static let  NO_JSON_CALLBACK = "1"
    static let  PER_PAGE = "15"
    static let  BOUNDING_BOX_HALF_WIDTH = 1.0
    static let  BOUNDING_BOX_HALF_HEIGHT = 1.0
    static let  LAT_MIN = -90.0
    static let  LAT_MAX = 90.0
    static let  LON_MIN = -180.0
    static let  LON_MAX = 180.0

  }
  
}

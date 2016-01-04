//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Kevin Murray on 12/26/15.
//  Copyright © 2015 Kevin Murray. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell : UICollectionViewCell {
  
  @IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var image: UIImageView!
  @IBOutlet weak var imagePlaceholder: UIView!
  
  // Cancel download task when collection view cell is reused
  var taskToCancelifCellIsReused: NSURLSessionTask? {
    
    didSet {
      if let taskToCancel = oldValue {
        taskToCancel.cancel()
      }
    }
  }
  
}

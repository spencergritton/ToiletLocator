//
//  LocationObjects.swift
//  Toilet Locator
//
//  Created by Spencer Gritton on 3/28/17.
//  Copyright © 2017 Spencer Gritton. All rights reserved.
//

import UIKit
import MapKit

class LocationObjects: NSObject, MKAnnotation {
    
    var identifier = "bathroom location"
    var title: String?
    var coordinate: CLLocationCoordinate2D
    
    init(name:String,lat:CLLocationDegrees,long:CLLocationDegrees){
        title = name
        coordinate = CLLocationCoordinate2DMake(lat, long)
    }
    
}

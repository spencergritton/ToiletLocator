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
 
    var identifier: String
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var distance: Double
    var phoneNumber: String
    var addressFinished: String
    
    init(name:String,lat:CLLocationDegrees,long:CLLocationDegrees,userCLLocation:CLLocation, phone:String, address:String, locationType: String){
        title = name
        coordinate = CLLocationCoordinate2DMake(lat, long)
        distance = Double(String(format: "%.2f", (userCLLocation.distance(from: CLLocation(latitude: lat, longitude: long)))*0.000621371))!
        phoneNumber = phone
        addressFinished = address
        identifier = locationType
        
    }
}

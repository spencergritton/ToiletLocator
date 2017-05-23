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
    
/*let userView = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
 let annotationPoint = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
 let distance = userView.distance(from: annotationPoint)*/
 
    var identifier = "bathroom location"
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var distance: Double
    var phoneNumber: String
    var addressFinished: String
    
    init(name:String,lat:CLLocationDegrees,long:CLLocationDegrees,userCLLocation:CLLocation, phone:String, address:String){
        title = name
        coordinate = CLLocationCoordinate2DMake(lat, long)
        distance = Double(String(format: "%.2f", (userCLLocation.distance(from: CLLocation(latitude: lat, longitude: long)))*0.000621371))!
        phoneNumber = phone
        addressFinished = address
        
    }
    
}

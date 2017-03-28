//
//  ViewController.swift
//  Toilet Locator
//
//  Created by Spencer Gritton on 3/9/17.
//  Copyright © 2017 Spencer Gritton. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    override func viewDidAppear(_ animated: Bool) {
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        mapView.delegate = self
        
        /*worldTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ViewController.AllowedToDo), userInfo: nil, repeats: true)*/
    }
    /*
    var worldTimer: Timer? = nil
    
    var amIAllowed = true
    func AllowedToDo() {
        amIAllowed = true
    }*/
    
    var manager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    var showTheseBusinesses = ["Gas", "Coffee", "Bathroom", "Food"]
    
    var locationLock = true
    @IBAction func test(_ sender: Any) {
        if locationLock == true {
            locationLock = false
        } else {
            locationLock = true
        }
    }
    
    
    // This function is called everytime user location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locationLock == false{
            return
        }
        
        // This function sets map to users location
        let location = locations[0]
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        
        let myLocations: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocations, span)
        mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        
        // For each business type the user selects, populateNearByPlaces with that business type
        for item in showTheseBusinesses {
            populateNearByPlacesLocationLockOn(place: item)
        }
        
    }
    
    func mapView(_ map: MKMapView, regionWillChangeAnimated animated: Bool) {
        if locationLock == true{
            return
        }
        // if we aren't locked on user location start sending MKLocalSearchRequests each time the map is dragged.
        for item in showTheseBusinesses {
            populateNearByPlacesLocationLockOff(place: item)
        }
    }
    

    
    var alreadyPopulatedPlaces: Array = [MKPointAnnotation]()
    
    func populateNearByPlacesLocationLockOff(place: String) {
        
        /* this function populates near by businesses onto the mapView.*/
        
        //Setting region to search for businesses
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        
        //Requesting search for businesses in region
        let request = MKLocalSearchRequest()
        //Requesting by business type
        request.naturalLanguageQuery = place
        request.region = region
        
        //Search for region
        let search = MKLocalSearch(request: request)
        // Remove previous annotations
        self.mapView.removeAnnotations(self.mapView.annotations)
        search.start { (response, error) in
            
            guard response != nil else {
                return
            }
            
            for item in (response?.mapItems)! {
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.placemark.name
                
                // if annotation already on map
                if self.alreadyPopulatedPlaces.contains(annotation) {
                    return
                }
                
                DispatchQueue.main.async {
                    self.alreadyPopulatedPlaces.append(annotation)
                    self.mapView.addAnnotation(annotation)
                }
                /*
                var dontDeleteMe = [MKPointAnnotation]()
                // Delete far away items
                for annotation in self.alreadyPopulatedPlaces {
                    for mapItem in (response?.mapItems)! {
                        if annotation.coordinate.longitude == mapItem.placemark.coordinate.longitude && annotation.coordinate.latitude == mapItem.placemark.coordinate.latitude{
                            dontDeleteMe.append(annotation)
                        }
                    }
                }
                
                for annotations in self.alreadyPopulatedPlaces {
                    if dontDeleteMe.contains(annotations) {
                        return
                    } else {
                        self.alreadyPopulatedPlaces = self.alreadyPopulatedPlaces.filter() { $0 !== annotations }
                        self.mapView.removeAnnotation(annotations)
                    }
                }
               */
            }
            
        }
        
    }
    
    
    func populateNearByPlacesLocationLockOn(place: String) {
        
        /* this function populates near by businesses onto the mapView.*/
        
        //Setting region to search for businesses
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
        
        //Requesting search for businesses in region
        let request = MKLocalSearchRequest()
        //Requesting by business type
        request.naturalLanguageQuery = place
        request.region = region
        
        //Search for region
        let search = MKLocalSearch(request: request)
        // Remove previous annotations
        self.mapView.removeAnnotations(self.mapView.annotations)
        search.start { (response, error) in
            
            guard response != nil else {
                return
            }
            
            for item in (response?.mapItems)! {
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.placemark.name
                
                // if annotation already on map
                if self.alreadyPopulatedPlaces.contains(annotation) {
                    return
                }
                
                DispatchQueue.main.async {
                    self.alreadyPopulatedPlaces.append(annotation)
                    self.mapView.addAnnotation(annotation)
                }
                /*
                 var dontDeleteMe = [MKPointAnnotation]()
                 // Delete far away items
                 for annotation in self.alreadyPopulatedPlaces {
                 for mapItem in (response?.mapItems)! {
                 if annotation.coordinate.longitude == mapItem.placemark.coordinate.longitude && annotation.coordinate.latitude == mapItem.placemark.coordinate.latitude{
                 dontDeleteMe.append(annotation)
                 }
                 }
                 }
                 
                 for annotations in self.alreadyPopulatedPlaces {
                 if dontDeleteMe.contains(annotations) {
                 return
                 } else {
                 self.alreadyPopulatedPlaces = self.alreadyPopulatedPlaces.filter() { $0 !== annotations }
                 self.mapView.removeAnnotation(annotations)
                 }
                 }
                 */
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
}







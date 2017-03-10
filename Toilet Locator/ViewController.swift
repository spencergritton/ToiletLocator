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
    
    var manager = CLLocationManager()
    @IBOutlet weak var map: MKMapView!
    var showTheseBusinesses = ["Gas", "Coffee", "Restrooms", "Bathrooms", "Rest Stop"]
    
    
    // This function is called everytime user location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // This function sets map to users location
        let location = locations[0]
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        
        let myLocations: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocations, span)
        map.setRegion(region, animated: true)
        self.map.showsUserLocation = true
        
        // For each business type the user selects, populateNearByPlaces with that business type
        for item in showTheseBusinesses {
            populateNearByPlaces(place: item)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }
    
    var alreadyPopulatedPlaces: Array = [MKMapItem]()
    
    func populateNearByPlaces(place: String) {
        /* this function populates near by businesses onto the mapView.*/
        
        //Setting region to search for businesses
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: self.map.userLocation.coordinate.latitude, longitude: self.map.userLocation.coordinate.longitude)
        
        //Requesting search for businesses in region
        let request = MKLocalSearchRequest()
        //Requesting by business type
        request.naturalLanguageQuery = place
        request.region = region
        
        //Search for region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            
            guard let response = response else {
                return
            }
                //If no error then add each item in the list of businesses to map as an annotation with the title of it's name
            for item in response.mapItems {
                
                //Check if annotation already added, if so don't add a new one.
                if self.alreadyPopulatedPlaces.contains(item) {
                    
                    return }
                
                else {
                    
                    // set the annotation on the map
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.placemark.name
                    self.alreadyPopulatedPlaces.append(item)
                    
                    DispatchQueue.main.async {
                        self.map.addAnnotation(annotation)
                    }
                }
                
                }
            // Delete annotations that are far away.
            for item in self.alreadyPopulatedPlaces {
                if response.mapItems.contains(item) {
                    return
                } else {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.placemark.name
                    self.alreadyPopulatedPlaces = self.alreadyPopulatedPlaces.filter() { $0 !== item }
                    self.map.removeAnnotation(annotation)
                }
            }
                
            }
        
            }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

            
}







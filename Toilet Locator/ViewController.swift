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
    
    // Initial calls for useful variables
    // Map Annotation Marker Image
    let pizzpin = #imageLiteral(resourceName: "Toiletmap")
    var manager = CLLocationManager()
    // Businesses for MKLocalSearch Query
    var showTheseBusinesses = ["Gas", "Coffee", "Bathroom", "Fast Food"]
    // Whether or not to focus on user Location
    var locationLock = true
    
    @IBOutlet weak var mapView: MKMapView!
    
    /* VIEW DID APPEAR
 - called everytime the mapView appear, if you go to settings
 then back it will appear again */
    override func viewDidAppear(_ animated: Bool) {
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        mapView.delegate = self
        
    }
    
    /* LOCATION LOCK BUTTON
 - Locks mapView on and off of user location so you can swipe around */
    @IBAction func test(_ sender: Any) {
        if locationLock == true {
            locationLock = false
        } else {
            locationLock = true
        }
    }
    
    /* MAP VIEW
 - Basically controls how certain annotations are shown, their callouts, images etc.. */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? LocationObjects{
            if let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.identifier){
                return view
            }else{
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.identifier)
                view.image = pizzpin
                view.isEnabled = true
                view.canShowCallout = true
                view.leftCalloutAccessoryView = UIImageView(image: pizzpin)
                return view
            }
        }
        return nil
    }
    
    /* DIDUPDATELOCATIONS
 - Extremely important, called anytime the users location is updated assuming locationLock is on */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Check if location lock is on, if not leave request
        if locationLock == false{
            return
        }
        
        // This function sets map to users location every time it updates
        let location = locations[0]
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        
        let myLocations: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocations, span)
        mapView.setRegion(region, animated: true)
        // Show the user location on the map
        self.mapView.showsUserLocation = true
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query
        // This is done through the populate function.. could use a better name.
        for item in showTheseBusinesses {
            populate(location: mapView.centerCoordinate, locationQuery: item)
        }
    }
    
    /* REGIONWILLCHANGE
 - This is if the user is swiping on the screen or rotating the map
 - Basically if they are scrolling away from their location to check out somewhere else this will
    populate the region with businesses */
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Check if location lock is off, if not don't do anything
        if locationLock == true {
            return
        }
        print("Yes")
        // if location lock is off then user is scrolling and wants to see businesses away 
        // from their personal location
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query
        // This is done through the populate function.. could use a better name.
        for item in showTheseBusinesses {
            populate(location: mapView.centerCoordinate, locationQuery: item)
        }
    }
    
    // Useful arrays for handling placing annotations on the map and avoiding double placing annotations
    var prePopulated = [LocationObjects]()
    var toPopulate = [LocationObjects]()
    
    /* DELETELOCATIONS
 - New function that is very useful on reducing clutter. 
 - Makes sure that if an annotation is not within ten miles of the users view that it is deleted to keep the app running freshly and without problems. This is done by calculating distance between the center of the map and all annotations on
     the map. */
    func deleteLocations() {
        //If an annotation is in the map but is not nearby.. Delete it
        for annotation in mapView.annotations {
            if (annotation is MKUserLocation) {
                continue
            } else {
                // Set userView to the Center mapView coords and annotationPoint to each annotation and check distance
                // between the two
                let userView = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
                let annotationPoint = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                let distance = userView.distance(from: annotationPoint)
                
                // Check how far away annotation is from user view, if over 10 miles then delete annotation
                if distance > 16093 {
                    mapView.removeAnnotation(annotation)
                    prePopulated = prePopulated.filter() { $0 !== annotation }
                } else {
                    continue
                }
            }
        }

    }
    
    /* POPULATE
 - The brain-child of the entire operation. This creates MKLocalSearch Queries for one item at a time.
 it then checks if the map has the local businesses on the map and if not adds them. */
    func populate(location: CLLocationCoordinate2D, locationQuery: String) {
        // Set region to search for
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        
        //Requesting search for businesses in region
        let request = MKLocalSearchRequest()
        //Requesting by business type
        request.naturalLanguageQuery = locationQuery
        request.region = region
        
        //Search for region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            
            // Only allow responses with business information
            guard response != nil else {
                return
            }
            
            // For each allowed item create a custom LocationObjects object using the data
            for item in (response?.mapItems)! {
                let annotation = LocationObjects(name: item.name!, lat: item.placemark.coordinate.latitude, long: item.placemark.coordinate.longitude)
                
                // if the annotation is already on the map skip it
                if self.prePopulated.contains(annotation) {
                    continue
                } else {
                    // else not on map already and append it to the toPopulate to deal with later on
                    self.toPopulate.append(annotation)
                }
            }
        }
        
        // Delete old and annotations more than ten miles away to conserve space
        deleteLocations()
        
        // Add annotations to map that are nearby and not already on the map
        for annotation in toPopulate {
            // If it's already on the map (prePopulated) move on
            if prePopulated.contains(annotation) {
                toPopulate = toPopulate.filter() { $0 !== annotation }
                continue
            } else {
                // The annotation is not already on the map and needs to be added
                prePopulated.append(annotation)
                mapView.addAnnotation(annotation)
                toPopulate = toPopulate.filter() { $0 !== annotation }
                
            }
            
        }
        
    }
}







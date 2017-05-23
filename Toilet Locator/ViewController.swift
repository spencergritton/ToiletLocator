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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource{
    
    // Initial calls for useful variables
    // Map Annotation Marker Image
    let annotationPin = #imageLiteral(resourceName: "Toiletmap")
    var manager = CLLocationManager()
    // Businesses for MKLocalSearch Query
    var showTheseBusinesses = ["Gas Stations", "Coffee", "Bathroom", "Fast Food"]
    // Whether or not to focus on user Location
    var locationLock = true
    // Map Declaration
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    /* VIEW DID APPEAR
 - called everytime the mapView appear, if you go to settings
 then back it will appear again */
    override func viewDidAppear(_ animated: Bool) {
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        mapView.delegate = self
        
        // Swipe Gesture Recognizer
        let swipeRecogonizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.generalGestureRecognizer(gesture:)))
        swipeRecogonizer.delegate = self
        // Pan Gesture Recognizer
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.generalGestureRecognizer(gesture:)))
        panRecognizer.delegate = self
        // Rotate Gesture Recognizer
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.generalGestureRecognizer(gesture:)))
        rotationRecognizer.delegate = self
        
        // Add all three gesture recognizers to the mapView
        mapView.addGestureRecognizer(swipeRecogonizer)
        mapView.addGestureRecognizer(panRecognizer)
        mapView.addGestureRecognizer(rotationRecognizer)
        
        // Pre-populate the map after the use location is zoomed in, this happens because the map isn't dragged and
        // the location doesn't move so there will be no pins on the map
        // This only adds "Gas Station" Annotations
        perform(#selector(ViewController.populate(locationQuery:)), with: "Gas Stations", afterDelay: 2)
    }
    
    /* LOCATION LOCK BUTTON
     - Locks mapView on and off of user location so you can swipe around */
    @IBAction func LocationLockButtonPressed(_ sender: Any) {
        if locationLock == true {
            locationLock = false
            LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
        } else {
            locationLock = true
            LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObject"), for: .normal)
        }
    }
    @IBOutlet weak var LocationLockButtonOutlet: UIButton!
    
    /* GESTURE RECOGNIZER
 - This function allows the mapView to recognize UIGestures outside of it's normal allotted tap and double tap
 - These normally only work on the view controller so this function is key to allowing them to work on the mapView. */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Check if the gesture is one of the three we are isoltating to use
        if (gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer || gestureRecognizer is UISwipeGestureRecognizer) {
            // if so allow the gesture recognizer's specified above to be used
            return true
        } else {
            return false
        }
    }

    
    
    /* GENERAL GESTURE RECOGNIZER
     This is the general gesture recognizer function.
 - If the user is location locked and decides to swipe, rotate, or pan they will be unlocked.
 - This is so that they can move around to look at other toilets and areas easily w/o the location lock button */
    
    func generalGestureRecognizer(gesture: UIGestureRecognizer) {
        if gesture.state == .ended && locationLock == true {
            locationLock = false
            LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
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
                view.image = annotationPin
                view.isEnabled = true
                view.canShowCallout = true
                view.leftCalloutAccessoryView = UIImageView(image: annotationPin)
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
            populate(locationQuery: item)
        }
        tableView.reloadData()
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
        // if location lock is off then user is scrolling and wants to see businesses away 
        // from their personal location
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query
        // This is done through the populate function.. could use a better name.
        for item in showTheseBusinesses {
            populate(locationQuery: item)
        }
        tableView.reloadData()
    }
    /* REGIONDIDCHANGE */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Check if location lock is off, if not don't do anything
        if locationLock == true {
            return
        }
        // if location lock is off then user is scrolling and wants to see businesses away
        // from their personal location
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query
        // This is done through the populate function.. could use a better name.
        for item in showTheseBusinesses {
            populate(locationQuery: item)
        }
        tableView.reloadData()
    }
    // ---------------------------------------- RegionDidChange and RegionWillChange do the same thing
    
    
    // Useful arrays for handling placing annotations on the map and avoiding double placing annotations
    var prePopulated = [LocationObjects]()
    var toPopulate = [LocationObjects]()
    
    
    /* DELETELOCATIONSTENMILESAWAY
 - New function that is very useful on reducing clutter. 
 - Makes sure that if an annotation is not within ten miles of the users view that it is deleted to keep the app running freshly and without problems. This is done by calculating distance between the center of the map and all annotations on
     the map. */
    func deleteLocationsTenMilesAway() {
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
    
    /* ADDANNOTATIONS
 - Function that adds annotations from the toPopulate que to the map, if not already on map
 - Then removes from the que and adds to the prePopulated AKA already on map list. */
    func addAnnotations() {
        mainAddLoop: for annotation in toPopulate {
            // If it's already on the map (prePopulated) move on
            // check if similar placed annotation is already on map
            for currentAnnotation in prePopulated {
                if currentAnnotation.coordinate.latitude == annotation.coordinate.latitude {
                    
                    toPopulate = toPopulate.filter() { $0 !== annotation }
                    continue mainAddLoop
                    
                }
            }
            
            if prePopulated.contains(annotation) {
                toPopulate = toPopulate.filter() { $0 !== annotation }
                continue mainAddLoop
                
            } else {
                // The annotation is not already on the map and needs to be added
                prePopulated.append(annotation)
                mapView.addAnnotation(annotation)
                toPopulate = toPopulate.filter() { $0 !== annotation }
            }
        }
    }
    
    
    /* POPULATE
 - The brain-child of the entire operation. This creates MKLocalSearch Queries for one item at a time.
 it then checks if the map has the local businesses on the map and if not adds them. */
    func populate(locationQuery: String) {
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
            mainLoop: for item in (response?.mapItems)! {
                
                // Finding phone number if available
                var phone:String
                if item.phoneNumber != nil {
                    phone = item.phoneNumber!
                } else {
                    phone = " "
                }
                
                // Finding address if available
                var address:String
                if (item.placemark.subThoroughfare != nil) {
                    address = item.placemark.subThoroughfare! + " " + item.placemark.thoroughfare! + " " + item.placemark.locality! + ", " + item.placemark.administrativeArea! + " " + item.placemark.postalCode!
                } else {
                    address = " "
                }
                
                let annotation = LocationObjects(name: item.name!, lat: item.placemark.coordinate.latitude, long: item.placemark.coordinate.longitude, userCLLocation: CLLocation(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude), phone: phone, address: address)

                // if the annotation is already on the map skip it
                if self.prePopulated.contains(annotation) {
                    continue mainLoop
                    
                } else {
                    // else not on map already and append it to the toPopulate to deal with later on
                    self.toPopulate.append(annotation)
                }
            }
        }
        
        // Delete old and annotations more than ten miles away to conserve space
        deleteLocationsTenMilesAway()
        
        // Add annotations to map that are nearby and not already on the map
        sortPrePopulated()
        addAnnotations()
    }
    
    /* SORTPREPOPULATED
 - Sorts prePopulated list in order of ascending distance */
    func sortPrePopulated() {
        prePopulated = prePopulated.sorted(by: { $0.distance < $1.distance } )
    }
    
    /* OPENANNOTATION
 - Thanks to stackoverflow.com/questions/2193843/how-to-open-call-out-mkannotatioview-programmatically-iphone-mapkit
 - Opens callout view of annotation passed into it */
    func openAnnotation(id: MKAnnotation) {
        _ = [mapView .selectAnnotation(id, animated: true)]
    }
    
    
    
    // START TABLE VIEW FUNCTIONS ------------------------------------------------------------------
    
    /* NUMBEROFROWSINSECTION
 - returns the number of rows in prePopulated, making the table as long as the array */
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return prePopulated.count
    }
    
    /* CELLFORROWAT
 - Customizes what each cell contains: text, images, etc.. */
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Tells the table to use the cell "Cell"
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        if prePopulated[indexPath.row].title != nil {
            
            cell.textLabel?.text = "\(prePopulated[indexPath.row].title!) \(prePopulated[indexPath.row].distance)"
            
        } else {
            // if there is no title make it blank
            cell.textLabel?.text = ""
            
        }
        return cell
    }
    
    /* DIDSELECTROWAT
 - What happens when the user clicks one of the cells in the table */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Turn location lock off, zoom map to the coordinates of the place selected.
        locationLock = false
        LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
        
       let region = MKCoordinateRegionMakeWithDistance(prePopulated[indexPath.row].coordinate, 500, 500)
        mapView.setRegion(region, animated: true)
        
        // Open the annotation callout view on the map
        openAnnotation(id: prePopulated[indexPath.row])
        
    }
}






